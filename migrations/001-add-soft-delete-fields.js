/**
 * Migration: Add Soft Delete Fields to All Tables
 * 
 * Adds deleted_at and deleted_by fields to all existing tables
 * for recycle bin functionality.
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = [
      'users',
      'buildings',
      'floors',
      'spaces',
      'bids',
      'contracts',
      'payments',
      'notifications',
      'private_visits',
      'role_hierarchy_config',
      'user_role_hierarchy'
    ];

    for (const table of tables) {
      // Add deleted_at column
      await queryInterface.addColumn(table, 'deleted_at', {
        type: Sequelize.DATE,
        allowNull: true
      });

      // Add deleted_by column
      await queryInterface.addColumn(table, 'deleted_by', {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      });

      // Create partial index on deleted_at for performance
      await queryInterface.sequelize.query(`
        CREATE INDEX idx_${table}_deleted_at 
        ON ${table}(deleted_at) 
        WHERE deleted_at IS NULL;
      `);
    }
  },

  async down(queryInterface, Sequelize) {
    const tables = [
      'users',
      'buildings',
      'floors',
      'spaces',
      'bids',
      'contracts',
      'payments',
      'notifications',
      'private_visits',
      'role_hierarchy_config',
      'user_role_hierarchy'
    ];

    for (const table of tables) {
      // Drop index
      await queryInterface.sequelize.query(`
        DROP INDEX IF EXISTS idx_${table}_deleted_at;
      `);

      // Remove columns
      await queryInterface.removeColumn(table, 'deleted_by');
      await queryInterface.removeColumn(table, 'deleted_at');
    }
  }
};

