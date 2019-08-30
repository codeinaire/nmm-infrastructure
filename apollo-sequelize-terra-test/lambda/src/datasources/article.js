const { DataSource } = require('apollo-datasource');

class ArticleAPI extends DataSource {
  constructor({ store }) {
    super();
    this.store = store;
  }

  /**
   * This is a function that gets called by ApolloServer when being setup.
   * This function gets called with the datasource config including things
   * like caches and context. We'll assign this.context to the request context
   * here, so we can know about the user making requests
   */
  initialize(config) {
    this.context = config.context;
  }

  async getArticles() {
    const articles = await this.store.articles.findAll({
      attributes: ['id', 'title', 'content', 'hashtag', 'type'],
      raw: true
    })
    console.log('This is articles!!!!!', articles);
    return articles;
  };

  async createArticles ({ articles }) {
    console.log('This is created articles', this.store);
    const created = await this.store.articles.bulkCreate(articles);
    console.log('This is created articles', created);
    return created;
  };

  async createArticle ({ article: { title, type, content, hashtag } }) {
    console.log('this is DATASOURCE$$$$$', title, type, content, hashtag);

    const createdArticle = await this.store.articles.findOrCreate({ where: {
      title, type, content, hashtag
    }});
    console.log('created ARTICLE', createdArticle);

    return createdArticle[0].dataValues;
  }
}

module.exports = ArticleAPI;