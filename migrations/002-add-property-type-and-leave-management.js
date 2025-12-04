/**
 * Migration: Add Property Type and Leave Management
 * 
 * - Adds property_type field to buildings table
 * - Adds leave management fields to users table
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Add property_type to buildings
    await queryInterface.addColumn('buildings', 'property_type', {
      type: Sequelize.ENUM('COMMERCIAL', 'RESIDENTIAL', 'MIXED_USE'),
      allowNull: false,
      defaultValue: 'COMMERCIAL'
    });

    // Create index on property_type
    await queryInterface.addIndex('buildings', ['property_type'], {
      name: 'idx_buildings_property_type'
    });

    // Add leave management fields to users
    await queryInterface.addColumn('users', 'leave_status', {
      type: Sequelize.ENUM('ACTIVE', 'ON_LEAVE', 'SICK_LEAVE', 'VACATION'),
      allowNull: false,
      defaultValue: 'ACTIVE'
    });

    await queryInterface.addColumn('users', 'leave_start_date', {
      type: Sequelize.DATEONLY,
      allowNull: true
    });

    await queryInterface.addColumn('users', 'leave_end_date', {
      type: Sequelize.DATEONLY,
      allowNull: true
    });

    // Create index on leave status for sales reps
    await queryInterface.sequelize.query(`
      CREATE INDEX idx_users_leave_status 
      ON users(leave_status, leave_start_date, leave_end_date) 
      WHERE role = 'SALES_REP';
    `);
  },

  async down(queryInterface, Sequelize) {
    // Drop indexes
    await queryInterface.removeIndex('buildings', 'idx_buildings_property_type');
    await queryInterface.sequelize.query(`
      DROP INDEX IF EXISTS idx_users_leave_status;
    `);

    // Remove columns
    await queryInterface.removeColumn('users', 'leave_end_date');
    await queryInterface.removeColumn('users', 'leave_start_date');
    await queryInterface.removeColumn('users', 'leave_status');
    await queryInterface.removeColumn('buildings', 'property_type');

    // Drop ENUM types
    await queryInterface.sequelize.query(`DROP TYPE IF EXISTS "enum_buildings_property_type";`);
    await queryInterface.sequelize.query(`DROP TYPE IF EXISTS "enum_users_leave_status";`);
  }
};

