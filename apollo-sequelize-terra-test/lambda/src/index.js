const { ApolloServer } = require('apollo-server-lambda');
const typeDefs = require('./schema');
const resolvers = require('./resolvers');

const { createDatabase } = require('./createDatabase');

const ArticleAPI = require('./datasources/article');
const ArticleS3API = require('./datasources/articleS3');

const store = createDatabase();
// const store2 = new store;

console.log('This is STORE', createDatabase, typeof store );

const server = new ApolloServer({
  typeDefs,
  resolvers,
  dataSources: () => {
    return {
      articleS3API: new ArticleS3API()
    }
  }
})

// server.listen().then(({ url }) => {
//   console.log(`Server is ready at ${url}`)
// }).catch(err => `You have an error: ${err}`)
exports.graphqlHandler = server.createHandler();