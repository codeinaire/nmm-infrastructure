const S3 = require('aws-sdk/clients/s3');
const { DataSource } = require('apollo-datasource');

// This is a fix to UnknownEndpoint: Inaccessible Host https://github.com/localstack/localstack/issues/43
// from this https://github.com/localstack/localstack/issues/338
//  s3ForcePathStyle is the fix.
// const paramsObject = {
//   apiVersion: '2006-03-01',
//   endpoint: 'http://localhost:4572',
//   accessKeyId: 'mock_access_key',
//   secretAccessKey: 'mock_access_key',
//   region: 'ap-southeast-2',
//   s3ForcePathStyle: true
// }

const s3 = new S3({region: 'ap-southeast-2'});

class ArticleS3API extends DataSource {
  constructor() {
    super();
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
    const params = {
      Bucket: 'no-meat-may-test-bucket',
      Key: 'test'
    }
    const promise = await new Promise((res, rej) => {
      s3.getObject(params, (err, data) => {
        console.log('this is err and data', err, data);
        if(err) {
          rej(err);
          return;
        }

        let buff = Buffer.from(data.Body, 'base64');
        let text = buff.toString('utf-8');
        res({
          id: data.ETag,
          title: data.ContentType,
          type: 'what',
          content: text,
          hashtag: ['hey yeah']
        })
      })
    });
    console.log('promise', promise);
    return promise;
  };

  async createArticles ({ articles }) {
    console.log('This is created articles', this.store);
    const created = await this.store.articles.bulkCreate(articles);
    console.log('This is created articles', created);
    return created;
  };

  async createArticle ({ article: { title, type, content, hashtag } }) {
    console.log('this is DATASOURCE$$$$$', title, type, content, hashtag);
    const params = {
      Bucket: 'no-meat-may-test-bucket',
      Key: 'test',
      Body: content
    }
    const promise = await new Promise((res, rej) => {
      s3.upload(params, (err, data) => {
        console.log('this is err and data', err, data);
        if(err) {
          rej(err);
          return;
        }
        res({
          id: data.ETag,
          title: data.Location,
          type,
          content,
          hashtag
        })
      })
    });
    console.log('promise', promise);
    return promise;
  }
}

module.exports = ArticleS3API;