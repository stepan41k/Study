using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MP6_2.Models
{
    [Table("student")]
    public class Student
    {
        [Key]
        [Column("kod_st")]
        public int kod_st { get; set; }

        [Column("fam")]
        public string fam { get; set; }

        [Column("name")]
        public string name { get; set; }

        [Column("otch")]
        public string otch { get; set; }

        [Column("gruppa")]
        public int gruppa { get; set; }
    }
}