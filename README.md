# Auction House Database Scenario

## Introduction

This report describes the design and implementation of a relational database that models an in-game auction house system. The database supports item definitions, seller listings, controlled item classifications and basic market analysis. The primary goal of the design is to ensure data integrity, reduce redundancy through normalization and allow realistic pricing and querying of auction data.

## Database Overview

The database consists of four core tables:

-	auction_items – stores item definitions
-	auction_listings – stores active auction listings
-	item_types – lookup table for item categories
-	rarities – lookup table fore item rarity tiers

The design separates item data from listing data. This prevents duplication and allows multiple listings to reference the same item.

## Table Design

### auction_items

The auction_items table represents the master catalogue of all items that can appear in the auction house.

Each item has:

-	A unique identifier (item_id)
-	A name and item level
-	A flag indicating whether it is stackable
-	An optional maximum stack size

A unique constraint is applied to the combination of item name, item level and rarity to prevent duplicate item definitions. This ensures that the same item cannot be inserted multiple times with identical attributes.
 
### auction_listings

The acution_listings table represents individual auction listings created by sellers.

Each listing:

-	References a specific item using foreign key
-	Stores seller name, quantity and unit price
-	Includes creation and expiration timestamps
-	Tracks listing status

Check constraints ensures that quantities are always positive and prices are never negative. Default values are used to automatically assign timestamps and listing status.

### item_types and rarities

The item_types and rarities tables are lookup tables used to standardize item classification.

These tables:

-	Store valid item categories and rarity tiers
-	Prevent invalid or inconsistent text values
-	Improve maintainability and data consistency

Each table uses a unique constraint to ensure no duplicate type or rarity names exist.

## Normalization and Schema Refactoring

Initially, item type and rarity were stored as text fields in the auction_items table. To improve normalization, these attributes were moved into separate lookup tables.

The refactoring process involved:

1.	Adding foreign key columns to auction_items
2.	Mapping existing text values to lookup table IDs
3.	Enforcing NOT NULL and foreign key constraints
4.	Removing the original text columns
5.	Rebuilding the uniqueness constraint using normalized IDs

This approach reduces redundancy and enforces referential integrity across the database.

## Data Seeding Strategy

### Item Seeding

A diverse set of items was inserted covering multiple item types, rarity levels and item levels. Both stackable and non-stackable items were included to reflect realistic auction behaviour.

### Listing Seeding

Auction listings were generated using controlled randomness:

-	Seller names were selected from a fixed pool
-	Quantities depend on whether an item is stackable
-	Expiry times range between 6 and 72 hours
-	Prices are generated dynamically based on item level and rarity

This approach produces realistic data suitable for testing and analysis.

## Pricing Model

A pricing multiplier was added to the rarities table to reflect how rarity affects item value. Higher rarity items receive larger multipliers.

Final prices are calculated using:

-	A base value derived from item level
-	A rarity multiplier
-	A bounded random factor to simulate market variation

A minimum price is enforced to prevent invalid values.

## Example Analysis Query

An aggregate query calculates the average unit price and total number of listings per rarity. This demonstrates:

-	Correct use of joins across normalized tables
-	The ability to derive market insights directly from SQL
-	How rarity impacts average pricing in the auction house

## Conclusion

The final database design effectively models a simplified auction house system using normalized relational tables and enforced data integrity. Item definitions are separated from transactional data, enabling realistic pricing behaviour and useful analytical queries. The schema can be extended in the future to support supply and demand mechanics, allowing prices to adjust based on item availability and market demand.
