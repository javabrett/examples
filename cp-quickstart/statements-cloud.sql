CREATE OR REPLACE STREAM pageviews WITH (kafka_topic='pageviews', value_format='AVRO');
CREATE OR REPLACE TABLE users (id STRING PRIMARY KEY) WITH (kafka_topic='users', value_format='PROTOBUF');
CREATE OR REPLACE STREAM pageviews_female AS SELECT users.id AS userid, pageid, regionid, gender FROM pageviews LEFT JOIN users ON pageviews.userid = users.id WHERE gender = 'FEMALE';
CREATE OR REPLACE STREAM pageviews_female_like_89 AS SELECT * FROM pageviews_female WHERE regionid LIKE '%_8' OR regionid LIKE '%_9';
CREATE OR REPLACE TABLE pageviews_regions WITH (key_format='JSON') AS SELECT gender, regionid , COUNT(*) AS numusers FROM pageviews_female WINDOW TUMBLING (size 30 second) GROUP BY gender, regionid HAVING COUNT(*) > 1;
CREATE OR REPLACE STREAM accomplished_female_readers WITH (value_format='JSON_SR') AS SELECT * FROM PAGEVIEWS_FEMALE WHERE CAST(SPLIT(PAGEID,'_')[2] as INT) >= 50;

CREATE OR REPLACE STREAM transactions WITH (kafka_topic='transactions', value_format='AVRO');
CREATE OR REPLACE TABLE credit_cards (id STRING PRIMARY KEY) WITH (kafka_topic='credit_cards', value_format='PROTOBUF');
