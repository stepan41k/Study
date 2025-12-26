using Microsoft.EntityFrameworkCore;
using MP7.Models;
using System.Collections.Generic;

namespace MP7
{
    public class DatabaseContext : DbContext
    {
        public DbSet<Student> Students { get; set; }
        public DbSet<User> Users { get; set; }

        public DatabaseContext() { }

        public DatabaseContext(DbContextOptions<DatabaseContext> options) : base(options) { }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseNpgsql("Host=5942e-rw.db.pub.dbaas.postgrespro.ru;Database=dbstud;Username=raspopov_si;Password=h#Lv7S6@%Y#3d");
        }
    }
}