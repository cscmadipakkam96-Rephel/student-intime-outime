-- CreateTable
CREATE TABLE "Attendance" (
    "id" SERIAL NOT NULL,
    "comn_enrol_no" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "inTime" TIMESTAMP(3),
    "outTime" TIMESTAMP(3),

    CONSTRAINT "Attendance_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Attendance_comn_enrol_no_idx" ON "Attendance"("comn_enrol_no");
