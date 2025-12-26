using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MP12_Server.Models
{
    [Table("Students")]
    public class Student
    {
        [Key]
        public int Id { get; set; }

        public string LastName { get; set; }  // Фамилия

        public string FirstName { get; set; } // Имя

        public string Role { get; set; }      // Роль (например, "студент")

        public string Email { get; set; }     // Почта

        public string Group { get; set; }     // Группа (на скриншоте "3093")
    }
}