const SQL = require('sequelize');
const ArticleModel = require('../models/article');

module.exports.createDatabase = () => {
  const db = new SQL('no-meat-may', 'no-meat-may', 'aoeui12345', {
    host: 'localhost',
    dialect: 'postgres'
  });

  const articles = ArticleModel(db, SQL);


  db.sync({ force: false }).then(() => {
    console.log('Database & tables created');
  })

  return { articles };
};

