using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
namespace MP11.Models
{
    [Table("Students")]
    public class Student
    {
        [Key]
        public int Id { get; set; } // Добавим ID как первичный ключ
        public string LastName { get; set; }  // Фамилия
        public string FirstName { get; set; } // Имя
        public string Role { get; set; }      // Роль
        public string Email { get; set; }     // E-mail
        public string Group { get; set; }     // Группа
    }
}