using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MP11.Models
{
    [Table("StudentTasks")]
    public class StudentTask
    {
        [Key]
        public int Id { get; set; }

        public int StudentId { get; set; } // Внешний ключ

        public string Title { get; set; } // Название проекта

        public int Value { get; set; }    // Значение для графика (цена/сложность)

        // Навигационное свойство (необязательно, но полезно)
        [ForeignKey("StudentId")]
        public virtual Student Student { get; set; }
    }
}