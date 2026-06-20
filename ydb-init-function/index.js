const { Driver, MetadataAuthService, Column, TableDescription, Types } = require('ydb-sdk');

const endpoint = process.env.YDB_ENDPOINT;
const database = process.env.YDB_DATABASE;

module.exports.handler = async (event, context) => {
    const authService = new MetadataAuthService();
    const driver = new Driver({ endpoint, database, authService });

    if (!await driver.ready(5000)) {
        throw new Error('YDB driver failed to become ready');
    }

    try {
        await driver.tableClient.withSession(async (session) => {
            await session.createTable(
                'messages',
                new TableDescription()
                    .withColumn(new Column('id', Types.optional(Types.UTF8)))
                    .withColumn(new Column('text', Types.optional(Types.UTF8)))
                    .withColumn(new Column('created_at', Types.optional(Types.TIMESTAMP)))
                    .withPrimaryKey('id')
            );
        });

        console.log('Table "messages" created successfully');
        return { statusCode: 200, body: JSON.stringify({ result: 'Schema created' }) };
    } catch (err) {
        if (err.message && err.message.includes('already exists')) {
            console.log('Table already exists, skipping');
            return { statusCode: 200, body: JSON.stringify({ result: 'Schema already exists' }) };
        }
        throw err;
    } finally {
        await driver.destroy();
    }
};
