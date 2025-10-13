const express = require('express');
const { ApolloServer } = require('apollo-server-express');
const dotenv = require('dotenv');
const connectDB = require('./src/config/db');
const typeDefs = require('./src/schema/typeDefs');
const resolvers = require('./src/resolvers/index'); // make sure path is correct
const cors = require('cors');

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

connectDB();

async function startServer() {
  const server = new ApolloServer({ typeDefs, resolvers, introspection: true });
  await server.start();
  server.applyMiddleware({ app, path: '/graphql' });

  const PORT = process.env.PORT || 5001;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running at http://localhost:${PORT}${server.graphqlPath}`);
  });
}

startServer();
