using Microsoft.EntityFrameworkCore;
using MP12_Server.Models;

namespace MP12_Server
{
    public class DatabaseContext : DbContext
    {
        // Ссылка на таблицу студентов
        public DbSet<Student> Students { get; set; }

        // Конструктор по умолчанию
        public DatabaseContext() { }

        // Конструктор с опциями (для передачи из Program.cs)
        public DatabaseContext(DbContextOptions<DatabaseContext> options) : base(options) { }

        // Конфигурация подключения
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            // Проверка, чтобы не переопределять конфигурацию, если она задана в Program.cs
            if (!optionsBuilder.IsConfigured)
            {
                // ВНИМАНИЕ: Замените Password на ваш пароль от Postgres
                optionsBuilder.UseNpgsql("Host=5942e-rw.db.pub.dbaas.postgrespro.ru;Database=dbstud;Username=raspopov_si;Password=h#Lv7S6@%Y#3d");
            }
        }
    }
}