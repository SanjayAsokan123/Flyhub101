import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import { ApolloServer } from "apollo-server-express";
import { graphqlUploadExpress } from "graphql-upload";
import jwt from "jsonwebtoken";
import { mergeTypeDefs, mergeResolvers } from "@graphql-tools/merge";
import { makeExecutableSchema } from "@graphql-tools/schema";
import { createServer } from "http";
import { WebSocketServer } from "ws";
import { useServer } from "graphql-ws/lib/use/ws";
import connectDB from "./config/db.js";
import { verifyFirebaseToken } from "./middleware/firebaseAuth.js";
import { pubsub } from "./pubsub.js";
import admin from "./config/firebaseAdmin.js";

// 🧩 Import merged typeDefs array & resolvers
import { typeDefs } from "./schema/typeDefs/index.js";
import {
  droneResolvers,
  partResolvers,
  accessoryResolvers,
  rentalResolvers,
  hirePilotResolvers,
  jobResolvers,
  orderResolvers,
  returnResolvers,
  serviceResolvers,
  regulatoryResolvers,
  buyerResolvers,
  sellerResolvers,
  notificationResolvers,
} from "./resolvers/index.js";

dotenv.config();
const PORT = process.env.PORT || 5002;

// 🚀 Start Server
const startServer = async () => {
  try {
    const app = express();

    // ========================
    // ✅ Middleware
    // ========================
    app.use(cors());
    app.use(express.json());
    app.use("/uploads", express.static("uploads"));
    app.use(graphqlUploadExpress({ maxFileSize: 10_000_000, maxFiles: 10 }));
    app.use(verifyFirebaseToken);

    // ========================
    // ✅ Connect MongoDB
    // ========================
    await connectDB();

    // ========================
    // ✅ Merge TypeDefs & Resolvers
    // ========================
    const baseTypeDefs = `
      type Query
      type Mutation
      type Subscription
    `;

    const mergedTypeDefs = mergeTypeDefs([baseTypeDefs, ...typeDefs]);
    const mergedResolvers = mergeResolvers([
      droneResolvers,
      partResolvers,
      accessoryResolvers,
      rentalResolvers,
      hirePilotResolvers,
      jobResolvers,
      orderResolvers,
      returnResolvers,
      serviceResolvers,
      regulatoryResolvers,
      buyerResolvers,
      sellerResolvers,
      notificationResolvers,
    ]);

    // ✅ Build Executable Schema
    const schema = makeExecutableSchema({
      typeDefs: mergedTypeDefs,
      resolvers: mergedResolvers,
    });

    // ========================
    // ✅ Apollo Server Setup
    // ========================
    const server = new ApolloServer({
      schema,
      context: ({ req }) => {
        const authHeader = req.headers.authorization || "";
        const refresh = req.headers["x-refresh-token"];
        const firebaseUser = req.firebaseUser || null;

        if (firebaseUser) return { firebaseUser, pubsub };

        if (authHeader.startsWith("Bearer ")) {
          const token = authHeader.split(" ")[1];
          try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            return { admin: decoded, pubsub };
          } catch (err) {
            if (err.name === "TokenExpiredError" && refresh) {
              try {
                const decodedRefresh = jwt.verify(
                  refresh,
                  process.env.JWT_REFRESH_SECRET
                );
                const newToken = jwt.sign(
                  {
                    id: decodedRefresh.id,
                    email: decodedRefresh.email,
                    role: "admin",
                  },
                  process.env.JWT_SECRET,
                  { expiresIn: "15m" }
                );
                return { admin: decodedRefresh, newToken, pubsub };
              } catch {
                console.log("❌ Invalid refresh token");
              }
            }
          }
        }

        return { pubsub };
      },
    });

    await server.start();
    server.applyMiddleware({ app, path: "/graphql" });

    // ========================
    // ✅ HTTP + WebSocket Setup
    // ========================
    const httpServer = createServer(app);
    const wsServer = new WebSocketServer({
      server: httpServer,
      path: "/graphql",
    });

    // Attach GraphQL Subscriptions
    useServer({ schema, context: () => ({ pubsub }) }, wsServer);

    // ========================
    // ✅ Start Server
    // ========================
    httpServer.listen(PORT, "0.0.0.0", () => {
      console.log("==================================================");
      console.log(`🌍 Environment: ${process.env.NODE_ENV || "development"}`);
      console.log(`🚀 GraphQL Endpoint: http://127.0.0.1:${PORT}/graphql`);
      console.log(`📡 Subscriptions: ws://127.0.0.1:${PORT}/graphql`);
      console.log(`🔥 Firebase Admin: Initialized`);
      console.log("==================================================");
    });
  } catch (err) {
    console.error("❌ Server startup error:", err);
  }
};

startServer();
