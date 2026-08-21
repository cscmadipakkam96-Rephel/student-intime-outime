// One-time script: copy data from Neon (source) to RDS (target).
// Usage: NEON_URL=... RDS_URL=... node migrate-neon-to-rds.js
const { PrismaClient } = require('./generated/prisma');
const { PrismaPg } = require('@prisma/adapter-pg');

async function main() {
  const neonUrl = process.env.NEON_URL;
  const rdsUrl = process.env.RDS_URL;

  if (!neonUrl || !rdsUrl) {
    console.error('Set NEON_URL and RDS_URL environment variables before running.');
    process.exit(1);
  }

  const neon = new PrismaClient({ adapter: new PrismaPg({ connectionString: neonUrl }) });
  const rds = new PrismaClient({
    adapter: new PrismaPg({ connectionString: rdsUrl, ssl: { rejectUnauthorized: false } }),
  });

  const registers = await neon.register.findMany();
  console.log(`Found ${registers.length} register row(s) in Neon`);
  for (const r of registers) {
    await rds.register.upsert({
      where: { comn_enrol_no: r.comn_enrol_no },
      update: { name: r.name, gmail: r.gmail, date_of_birth: r.date_of_birth },
      create: {
        comn_enrol_no: r.comn_enrol_no,
        name: r.name,
        gmail: r.gmail,
        date_of_birth: r.date_of_birth,
      },
    });
  }
  console.log('Register table migrated.');

  const attendance = await neon.attendance.findMany();
  console.log(`Found ${attendance.length} attendance row(s) in Neon`);
  for (const a of attendance) {
    const existing = await rds.attendance.findFirst({
      where: { comn_enrol_no: a.comn_enrol_no, date: a.date },
    });
    if (!existing) {
      await rds.attendance.create({
        data: {
          comn_enrol_no: a.comn_enrol_no,
          date: a.date,
          inTime: a.inTime,
          outTime: a.outTime,
        },
      });
    }
  }
  console.log('Attendance table migrated.');

  await neon.$disconnect();
  await rds.$disconnect();
  console.log('Done.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
