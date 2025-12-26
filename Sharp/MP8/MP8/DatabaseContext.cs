using Microsoft.EntityFrameworkCore;
using MP8.Models;

namespace MP8
{
    public class DatabaseContext : DbContext
    {
        // 4.2. Статичное поле
        private static DatabaseContext _context;

        public DbSet<Student> Students { get; set; }
        public DbSet<User> Users { get; set; }

        public DatabaseContext() { }

        public DatabaseContext(DbContextOptions<DatabaseContext> options) : base(options) { }

        // 4.3. Метод получения экземпляра (Singleton)
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