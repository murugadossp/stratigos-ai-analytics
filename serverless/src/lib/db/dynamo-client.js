/**
 * DynamoDB Client
 * 
 * Provides utility functions for interacting with DynamoDB.
 */

const AWS = require('aws-sdk');

// Initialize DynamoDB client
const dynamoDB = new AWS.DynamoDB.DocumentClient();

/**
 * Get an item from DynamoDB
 * 
 * @param {string} tableName - DynamoDB table name
 * @param {Object} key - Key object (e.g., { id: 'abc123' })
 * @returns {Promise<Object>} - Item from DynamoDB
 */
async function getItem(tableName, key) {
  const params = {
    TableName: tableName,
    Key: key
  };
  
  const result = await dynamoDB.get(params).promise();
  return result.Item;
}

/**
 * Put an item in DynamoDB
 * 
 * @param {string} tableName - DynamoDB table name
 * @param {Object} item - Item to put in DynamoDB
 * @returns {Promise<Object>} - Result from DynamoDB
 */
async function putItem(tableName, item) {
  const params = {
    TableName: tableName,
    Item: item
  };
  
  return dynamoDB.put(params).promise();
}

/**
 * Update an item in DynamoDB
 * 
 * @param {string} tableName - DynamoDB table name
 * @param {Object} key - Key object (e.g., { id: 'abc123' })
 * @param {Object} updates - Updates to apply
 * @returns {Promise<Object>} - Updated item
 */
async function updateItem(tableName, key, updates) {
  // Build update expression and attribute values
  const updateExpressions = [];
  const expressionAttributeNames = {};
  const expressionAttributeValues = {};
  
  Object.entries(updates).forEach(([field, value]) => {
    const attributeName = `#${field}`;
    const attributeValue = `:${field}`;
    
    updateExpressions.push(`${attributeName} = ${attributeValue}`);
    expressionAttributeNames[attributeName] = field;
    expressionAttributeValues[attributeValue] = value;
  });
  
  // Add updatedAt timestamp
  const now = new Date().toISOString();
  updateExpressions.push('#updatedAt = :updatedAt');
  expressionAttributeNames['#updatedAt'] = 'updatedAt';
  expressionAttributeValues[':updatedAt'] = now;
  
  const params = {
    TableName: tableName,
    Key: key,
    UpdateExpression: `SET ${updateExpressions.join(', ')}`,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: 'ALL_NEW'
  };
  
  const result = await dynamoDB.update(params).promise();
  return result.Attributes;
}

/**
 * Delete an item from DynamoDB
 * 
 * @param {string} tableName - DynamoDB table name
 * @param {Object} key - Key object (e.g., { id: 'abc123' })
 * @returns {Promise<Object>} - Result from DynamoDB
 */
async function deleteItem(tableName, key) {
  const params = {
    TableName: tableName,
    Key: key
  };
  
  return dynamoDB.delete(params).promise();
}

/**
 * Query items from DynamoDB
 * 
 * @param {string} tableName - DynamoDB table name
 * @param {string} keyConditionExpression - Key condition expression
 * @param {Object} expressionAttributeValues - Expression attribute values
 * @param {Object} options - Additional options (index, limit, etc.)
 * @returns {Promise<Array>} - Items from DynamoDB
 */
async function queryItems(tableName, keyConditionExpression, expressionAttributeValues, options = {}) {
  const params = {
    TableName: tableName,
    KeyConditionExpression: keyConditionExpression,
    ExpressionAttributeValues: expressionAttributeValues,
    ...options
  };
  
  const result = await dynamoDB.query(params).promise();
  return result.Items;
}

/**
 * Scan items from DynamoDB
 * 
 * @param {string} tableName - DynamoDB table name
 * @param {Object} options - Additional options (filter, limit, etc.)
 * @returns {Promise<Array>} - Items from DynamoDB
 */
async function scanItems(tableName, options = {}) {
  const params = {
    TableName: tableName,
    ...options
  };
  
  const result = await dynamoDB.scan(params).promise();
  return result.Items;
}

module.exports = {
  getItem,
  putItem,
  updateItem,
  deleteItem,
  queryItems,
  scanItems
};
