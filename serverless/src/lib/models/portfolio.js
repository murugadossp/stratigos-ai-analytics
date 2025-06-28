/**
 * Portfolio Model
 * 
 * Defines the structure and validation for portfolio objects.
 */

const Joi = require('joi');
const { v4: uuidv4 } = require('uuid');

// Portfolio schema for validation
const portfolioSchema = Joi.object({
  id: Joi.string().uuid(),
  name: Joi.string().required().min(1).max(100),
  description: Joi.string().allow('').max(500),
  assets: Joi.object().pattern(
    Joi.string().min(1).max(10), // Asset ticker
    Joi.number().min(0).max(1)   // Asset weight
  ).required(),
  createdAt: Joi.date().iso(),
  updatedAt: Joi.date().iso()
}).unknown(false);

/**
 * Create a new portfolio object
 * 
 * @param {Object} data - Portfolio data
 * @returns {Object} Portfolio object
 */
function createPortfolio(data) {
  const now = new Date().toISOString();
  
  // Create portfolio object with defaults
  const portfolio = {
    id: data.id || uuidv4(),
    name: data.name,
    description: data.description || '',
    assets: data.assets,
    createdAt: data.createdAt || now,
    updatedAt: data.updatedAt || now
  };
  
  // Validate portfolio
  const { error } = portfolioSchema.validate(portfolio);
  if (error) {
    throw new Error(`Invalid portfolio: ${error.message}`);
  }
  
  // Validate that asset weights sum to 1.0
  const totalWeight = Object.values(portfolio.assets).reduce((sum, weight) => sum + weight, 0);
  if (Math.abs(totalWeight - 1.0) > 0.0001) {
    throw new Error(`Asset weights must sum to 1.0, got ${totalWeight}`);
  }
  
  return portfolio;
}

/**
 * Validate a portfolio object
 * 
 * @param {Object} portfolio - Portfolio object to validate
 * @returns {boolean} True if valid, throws error if invalid
 */
function validatePortfolio(portfolio) {
  const { error } = portfolioSchema.validate(portfolio);
  if (error) {
    throw new Error(`Invalid portfolio: ${error.message}`);
  }
  
  // Validate that asset weights sum to 1.0
  const totalWeight = Object.values(portfolio.assets).reduce((sum, weight) => sum + weight, 0);
  if (Math.abs(totalWeight - 1.0) > 0.0001) {
    throw new Error(`Asset weights must sum to 1.0, got ${totalWeight}`);
  }
  
  return true;
}

module.exports = {
  createPortfolio,
  validatePortfolio,
  portfolioSchema
};
