'use strict';
module.exports = (sequelize, DataTypes) => {
  const Article = sequelize.define('Articles', {
    title: DataTypes.STRING,
    content: DataTypes.TEXT,
    hashtag: DataTypes.ARRAY(DataTypes.STRING),
    type: DataTypes.STRING
  }, {});
  Article.associate = function(models) {
    // associations can be defined here
  };
  return Article;
};