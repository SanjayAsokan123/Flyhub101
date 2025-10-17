import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import { ApolloServer } from "apollo-server-express";
import { graphqlUploadExpress } from "graphql-upload";
import jwt from "jsonwebtoken";
import connectDB from "./config/db.js";

// 🧩 GraphQL Merge Tools
import { mergeTypeDefs, mergeResolvers } from "@graphql-tools/merge";

// 🧩 Schemas
import { droneTypeDefs } from "./schema/drone.schema.js";
import { partTypeDefs } from "./schema/parts.schema.js";
import { accessoryTypeDefs } from "./schema/accessories.schema.js";
import { seller_buyer_TypeDefs } from "./schema/seller_buyer.schema.js";
import { adminTypeDefs } from "./schema/admin.schema.js";
import { rentalTypeDefs } from "./schema/rental.schema.js";

// 🧩 Resolvers
import { droneResolvers } from "./resolvers/drone.resolver.js";
import { partResolvers } from "./resolvers/parts.resolver.js";
import { accessoryResolvers } from "./resolvers/accessories.resolver.js";
import { seller_buyer_Resolvers } from "./resolvers/seller_buyer.resolver.js";
import { adminResolvers } from "./resolvers/admin.resolver.js";
import { rentalResolvers } from "./resolvers/rental.resolver.js";

import { marketplaceTypeDefs } from "./schema/marketplace.schema.js";
import { marketplaceResolvers } from "./resolvers/marketplace.resolver.js";

import { verifyFirebaseToken } from "./middleware/firebaseAuth.js";

dotenv.config();
const PORT = process.env.PORT || 4000;

const startServer = async () => {
  try {
    const app = express();

    // ✅ Middleware
    app.use(cors());
    app.use(express.json());
    app.use("/uploads", express.static("uploads"));
    app.use(graphqlUploadExpress({ maxFileSize: 10_000_000, maxFiles: 10 }));
// 🔥 Firebase token verification middleware
app.use(verifyFirebaseToken);
    // ✅ Connect MongoDB
    await connectDB();

    // ✅ Merge all typeDefs and resolvers
    const typeDefs = mergeTypeDefs([
      droneTypeDefs,
      partTypeDefs,
      accessoryTypeDefs, // ✅ Added accessories
        marketplaceTypeDefs,
      seller_buyer_TypeDefs,
      adminTypeDefs,
      rentalTypeDefs,
    ]);

    const resolvers = mergeResolvers([
      droneResolvers,
      partResolvers,
      accessoryResolvers, // ✅ Added accessories
       marketplaceResolvers,
      seller_buyer_Resolvers,
      adminResolvers,
      rentalResolvers,
    ]);

    // ✅ Apollo Server Context (JWT Auth)
    const server = new ApolloServer({
      typeDefs,
      resolvers,
      context: ({ req }) => {
        const auth = req.headers.authorization || "";
        const refresh = req.headers["x-refresh-token"];
        const firebaseUser = req.firebaseUser || null;
            return { firebaseUser };

        if (auth.startsWith("Bearer ")) {
          const token = auth.split(" ")[1];
          try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            return { admin: decoded };
          } catch (err) {
            if (err.name === "TokenExpiredError" && refresh) {
              try {
                const decodedRefresh = jwt.verify(refresh, process.env.JWT_REFRESH_SECRET);
                const newToken = jwt.sign(
                  { id: decodedRefresh.id, email: decodedRefresh.email, role: "admin" },
                  process.env.JWT_SECRET,
                  { expiresIn: "15m" }
                );
                return { admin: decodedRefresh, newToken };
              } catch {
                console.log("❌ Invalid refresh token");
              }
            }
            console.log("❌ Invalid or expired access token");
          }
        }
        return {};
      },
    });

    // ✅ Start Apollo Server
    await server.start();
    server.applyMiddleware({ app, path: "/graphql" });

    // ✅ Start Express
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`🚀 Server running at http://127.0.0.1:${PORT}${server.graphqlPath}`);
    });
  } catch (err) {
    console.error("❌ Server startup error:", err);
  }
};

startServer();
