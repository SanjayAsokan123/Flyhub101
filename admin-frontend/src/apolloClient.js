import { ApolloClient, InMemoryCache, createHttpLink, ApolloLink, Observable } from "@apollo/client";
import { setContext } from "@apollo/client/link/context";

// ✅ Backend endpoint
const httpLink = createHttpLink({
  uri: "http://127.0.0.1:5001/graphql",
});

// ✅ Auth link: attaches the access token to each request
const authLink = setContext((_, { headers }) => {
  const token = localStorage.getItem("accessToken");
  return {
    headers: {
      ...headers,
      Authorization: token ? `Bearer ${token}` : "",
    },
  };
});

// ✅ Silent refresh and retry link
const refreshLink = new ApolloLink((operation, forward) => {
  return new Observable((observer) => {
    let subscription;

    // Function to handle the response
    const handleNext = (response) => {
      const errors = response.errors || [];
      const isUnauthorized = errors.some(
        (err) =>
          err.message.includes("Unauthorized") ||
          err.message.includes("expired") ||
          err.message.includes("Invalid token")
      );

      if (!isUnauthorized) {
        observer.next(response);
        observer.complete();
        return;
      }

      console.warn("🔄 Access token expired, attempting refresh...");

      const refreshToken = localStorage.getItem("refreshToken");
      if (!refreshToken) {
        console.error("❌ No refresh token found, logging out.");
        logoutUser();
        return;
      }

      // Call refresh token mutation directly
      fetch("http://127.0.0.1:5001/graphql", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: `
            mutation {
              refreshAdminToken(refreshToken: "${refreshToken}") {
                success
                token
              }
            }
          `,
        }),
      })
        .then((res) => res.json())
        .then((data) => {
          const newToken = data?.data?.refreshAdminToken?.token;
          if (newToken) {
            console.log("✅ Token refreshed successfully!");
            localStorage.setItem("accessToken", newToken);

            // Retry the failed operation with new token
            const oldHeaders = operation.getContext().headers;
            operation.setContext({
              headers: {
                ...oldHeaders,
                Authorization: `Bearer ${newToken}`,
              },
            });

            // Resend the original request
            subscription = forward(operation).subscribe(observer);
          } else {
            console.error("❌ Token refresh failed, logging out.");
            logoutUser();
          }
        })
        .catch((err) => {
          console.error("❌ Token refresh error:", err);
          logoutUser();
        });
    };

    // Start original request
    subscription = forward(operation).subscribe({
      next: handleNext,
      error: (err) => observer.error(err),
      complete: () => observer.complete(),
    });

    return () => {
      if (subscription) subscription.unsubscribe();
    };
  });
});

// ✅ Logout utility (shared)
function logoutUser() {
  localStorage.removeItem("accessToken");
  localStorage.removeItem("refreshToken");
  window.location.href = "/login";
}

// ✅ Apollo Client Setup
export const client = new ApolloClient({
  link: ApolloLink.from([refreshLink, authLink, httpLink]),
  cache: new InMemoryCache(),
  connectToDevTools: true,
});
