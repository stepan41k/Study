using System.Text.Json.Serialization;

namespace MP12_Client
{
    public class Student
    {

        public int Id { get; set; }
        public string LastName { get; set; }
        public string FirstName { get; set; }
        public string Role { get; set; }
        public string Email { get; set; }
        public string Group { get; set; }

        public override string ToString()
        {
            return $"ID: {Id} | {LastName} {FirstName} | {Group} | {Role} | {Email}";
        }
    }
}