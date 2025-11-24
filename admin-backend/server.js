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
import multer from "multer";
import { uploadToFirebase } from "./utils/uploadToFirebase.js";
import sellerAuthRouter from "./routes/sellerAuth.js";

// GraphQL Schema + Resolvers
import { typeDefs } from "./schema/typeDefs/index.js";
import { resolves } from "./resolvers/resolves/index.js";

dotenv.config();
const PORT = process.env.PORT || 5001;

const startServer = async () => {
  try {
    const app = express();

    // =======================================================
    // 🌍 Core Middlewares
    // =======================================================
    app.use(cors());
    app.use(express.json());
    app.use("/uploads", express.static("uploads"));

    // =======================================================
    // 🔥 IMPORTANT: Firebase Auth Middleware FIRST
    // =======================================================
    app.use(verifyFirebaseToken);

    // Auth route
    app.use("/auth", sellerAuthRouter);

    // =======================================================
    // 📁 Multer Setup (File Upload)
    // =======================================================
    const storage = multer.memoryStorage();
    const upload = multer({ storage });

    // Health Check
    app.get("/healthz", (_req, res) => res.json({ ok: true }));

    // =======================================================
    // 📤 Firebase File Upload Route
    // =======================================================
    app.post(
      "/upload",
      upload.single("file"),
      async (req, res) => {
        try {
          if (!req.file) {
            return res.status(400).json({ success: false, message: "No file uploaded" });
          }

          const folder = req.body.folder || "hire-pilots";
          const firebaseUser = req.firebaseUser;
          const publicUrl = await uploadToFirebase(req.file, folder);

          console.log(`📤 ${firebaseUser?.email || "anonymous"} uploaded to ${folder}`);

          res.json({
            success: true,
            url: publicUrl,
            uploader: firebaseUser?.email,
            message: "✅ File uploaded successfully",
          });
        } catch (err) {
          console.error("❌ Upload Error:", err);
          res.status(500).json({ success: false, message: err.message });
        }
      }
    );

    // =======================================================
    // 📦 GraphQL Upload Middleware
    // =======================================================
    app.use(graphqlUploadExpress({ maxFileSize: 10_000_000, maxFiles: 10 }));

    // =======================================================
    // 🛢 MongoDB Connect
    // =======================================================
    await connectDB();

    // =======================================================
    // 🧩 Merge Schemas
    // =======================================================
    const baseTypeDefs = `
      type Query
      type Mutation
      type Subscription
    `;

    const mergedTypeDefs = mergeTypeDefs([baseTypeDefs, ...typeDefs]);
    const mergedResolvers = mergeResolvers([...resolves]);

    const schema = makeExecutableSchema({
      typeDefs: mergedTypeDefs,
      resolvers: mergedResolvers,
    });

    // =======================================================
    // 🚀 Apollo Server
    // =======================================================
    const server = new ApolloServer({
      schema,
      context: ({ req }) => {
        const authHeader = req.headers.authorization || "";
        const refresh = req.headers["x-refresh-token"];
        const firebaseUser = req.firebaseUser || null;

        // 🔥 Firebase User available
        if (firebaseUser) return { firebaseUser, pubsub };

        // 🔐 Admin JWT Token
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

    // =======================================================
    // 🔔 WebSocket Setup
    // =======================================================
    const httpServer = createServer(app);
    const wsServer = new WebSocketServer({
      server: httpServer,
      path: "/graphql",
    });

    useServer({ schema, context: () => ({ pubsub }) }, wsServer);

    // =======================================================
    // 🚀 Start Server
    // =======================================================
    httpServer.listen(PORT, "0.0.0.0", () => {
      console.log("==================================================");
      console.log(`🌍 Environment: ${process.env.NODE_ENV || "development"}`);
      console.log(`🚀 GraphQL Endpoint: http://127.0.0.1:${PORT}/graphql`);
      console.log(`📡 Subscriptions: ws://127.0.0.1:${PORT}/graphql`);
      console.log(`📥 Upload endpoint: http://127.0.0.1:${PORT}/upload`);
      console.log(`🔥 Firebase Admin: Initialized`);
      console.log("==================================================");
    });

  } catch (err) {
    console.error("❌ Server startup error:", err);
  }
};

startServer();
