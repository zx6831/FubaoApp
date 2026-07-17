ALTER TABLE "Plan"
ADD COLUMN "subtitle" TEXT,
ADD COLUMN "timezone" TEXT NOT NULL DEFAULT 'Asia/Shanghai',
ADD COLUMN "schedule" JSONB NOT NULL DEFAULT '{"time":"08:00","daysOfWeek":[1,2,3,4,5,6,7]}'::jsonb;
