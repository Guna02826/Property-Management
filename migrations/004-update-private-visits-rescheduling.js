/**
 * Migration: Update Private Visits for Rescheduling
 * 
 * Adds rescheduling fields to private_visits table
 * and updates status enum to include RESCHEDULED.
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Add RESCHEDULED to status enum
    await queryInterface.sequelize.query(`
      ALTER TYPE "enum_private_visits_status" 
      ADD VALUE IF NOT EXISTS 'RESCHEDULED';
    `);

    // Add rescheduling tracking fields
    await queryInterface.addColumn('private_visits', 'rescheduled_from_visit_id', {
      type: Sequelize.UUID,
      allowNull: true,
      references: {
        model: 'private_visits',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    });

    await queryInterface.addColumn('private_visits', 'rescheduled_reason', {
      type: Sequelize.TEXT,
      allowNull: true
    });

    // Create index on rescheduled_from_visit_id
    await queryInterface.addIndex('private_visits', ['rescheduled_from_visit_id'], {
      name: 'idx_private_visits_rescheduled_from'
    });
  },

  async down(queryInterface, Sequelize) {
    // Remove indexes
    await queryInterface.removeIndex('private_visits', 'idx_private_visits_rescheduled_from');

    // Remove columns
    await queryInterface.removeColumn('private_visits', 'rescheduled_reason');
    await queryInterface.removeColumn('private_visits', 'rescheduled_from_visit_id');

    // Note: PostgreSQL doesn't support removing enum values easily
    // This would require recreating the enum type
    // For production, consider keeping the enum value for backward compatibility
  }
};

