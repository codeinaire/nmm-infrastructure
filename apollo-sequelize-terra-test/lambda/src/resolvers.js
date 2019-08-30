module.exports = {
  Query: {
    articles: (_, __, { dataSources }) => {
      console.log('RESOLVERS', dataSources );
      return dataSources.articleS3API.getArticles()
    }
  },
  Mutation: {
    createArticles: (_, { articles }, { dataSources }) => {
      console.log('RESOLVERS', dataSources );
      return dataSources.articleS3API.createArticles({ articles })
    },
    createArticle: (_, { article }, { dataSources }) => {
      console.log('RESOLVERS@@@@@', dataSources, article );
      return dataSources.articleS3API.createArticle({ article })
    }
  }
}