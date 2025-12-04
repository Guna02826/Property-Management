/**
 * Migration: Create Parking Spaces Table
 * 
 * Creates parking_spaces table for parking management
 * with assignment tracking to users and contracts.
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('parking_spaces', {
      id: {
        type: Sequelize.UUID,
        primaryKey: true,
        defaultValue: Sequelize.literal('gen_random_uuid()')
      },
      building_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'buildings',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'RESTRICT'
      },
      space_number: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      parking_type: {
        type: Sequelize.ENUM('STANDARD', 'RESERVED', 'HANDICAP', 'ELECTRIC_CHARGING'),
        allowNull: false,
        defaultValue: 'STANDARD'
      },
      is_available: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true
      },
      assigned_to_user_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      assigned_to_contract_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'contracts',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      assigned_at: {
        type: Sequelize.DATE,
        allowNull: true
      },
      monthly_fee: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: true
      },
      currency: {
        type: Sequelize.STRING(3),
        allowNull: false,
        defaultValue: 'USD'
      },
      notes: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('NOW()')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('NOW()')
      },
      created_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id'
        }
      },
      updated_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id'
        }
      },
      deleted_at: {
        type: Sequelize.DATE,
        allowNull: true
      },
      deleted_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id'
        }
      }
    });

    // Create unique constraint on building_id + space_number
    await queryInterface.addConstraint('parking_spaces', {
      fields: ['building_id', 'space_number'],
      type: 'unique',
      name: 'parking_spaces_building_space_unique'
    });

    // Create indexes
    await queryInterface.addIndex('parking_spaces', ['building_id'], {
      name: 'idx_parking_spaces_building_id'
    });

    await queryInterface.addIndex('parking_spaces', ['assigned_to_user_id'], {
      name: 'idx_parking_spaces_assigned_to_user'
    });

    await queryInterface.addIndex('parking_spaces', ['assigned_to_contract_id'], {
      name: 'idx_parking_spaces_assigned_to_contract'
    });

    await queryInterface.addIndex('parking_spaces', ['is_available'], {
      name: 'idx_parking_spaces_available',
      where: {
        is_available: true
      }
    });

    await queryInterface.sequelize.query(`
      CREATE INDEX idx_parking_spaces_deleted_at 
      ON parking_spaces(deleted_at) 
      WHERE deleted_at IS NULL;
    `);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('parking_spaces');
    await queryInterface.sequelize.query(`DROP TYPE IF EXISTS "enum_parking_spaces_parking_type";`);
  }
};

