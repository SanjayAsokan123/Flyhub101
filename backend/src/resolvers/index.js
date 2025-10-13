require('dotenv').config();
const mongoose = require('mongoose');
const { ApolloServer } = require('apollo-server');
const typeDefs = require('../schema/typeDefs');
const resolvers = require('../resolvers/index');

async function start() {
  await mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('MongoDB connected');

  const server = new ApolloServer({
    typeDefs,
    resolvers,
    // playground / introspection allowed for development
    introspection: true,
  });

  const { url } = await server.listen({ port: process.env.PORT || 4000 });
//  console.log(`GraphQL server ready at ${url}`);
}

start().catch(err => { console.error(err); process.exit(1); });
