using Microsoft.EntityFrameworkCore;
using MP11.Models; // Или MP7.Models

namespace MP11
{
    public class DatabaseContext : DbContext
    {
        private static DatabaseContext _context;

        public DbSet<Student> Students { get; set; }
        public DbSet<User> Users { get; set; }

        // --- ДОБАВЛЯЕМ ВОТ ЭТУ СТРОКУ ---
        public DbSet<StudentTask> StudentTasks { get; set; }
        // --------------------------------

        public DatabaseContext() { }

        public DatabaseContext(DbContextOptions<DatabaseContext> options) : base(options) { }

        public static DatabaseContext GetContext()
        {
            if (_context == null)
                _context = new DatabaseContext();
            return _context;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseNpgsql("Host=5942e-rw.db.pub.dbaas.postgrespro.ru;Database=dbstud;Username=raspopov_si;Password=h#Lv7S6@%Y#3d");
        }
    }
}