using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MP11.Models
{
    [Table("m_users")]
    public class User
    {
        [Key]
        public int Id { get; set; }

        public string FullName { get; set; } // Для поля "ФИО"

        [Required]
        public string Username { get; set; } // Для поля "Имя пользователя"

        [Required]
        public string Password { get; set; } // Для поля "Пароль"
    }
}