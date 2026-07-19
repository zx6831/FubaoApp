-- Store the latest in-app reminder independently from the scheduled reminder time.
ALTER TABLE "DailyTask" ADD COLUMN "remindedAt" TIMESTAMP(3);
