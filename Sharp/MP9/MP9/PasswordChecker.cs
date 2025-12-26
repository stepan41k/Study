using System;
using System.Linq; // Необходимо для методов Any и Intersect

namespace MP9_Password
{
    public class PasswordChecker
    {
        public static bool ValidatePassword(string password)
        {
            // Проверка на null или пустую строку (хорошая практика, хотя в задании не указана явно)
            if (string.IsNullOrEmpty(password))
                return false;

            // 1. Проверка длины (от 8 до 20 символов)
            if (password.Length < 8 || password.Length > 20)
                return false;

            // 2. Проверка наличия строчных букв (lowercase)
            if (!password.Any(char.IsLower))
                return false;

            // 3. Проверка наличия прописных букв (uppercase)
            if (!password.Any(char.IsUpper))
                return false;

            // 4. Проверка наличия цифр
            if (!password.Any(char.IsDigit))
                return false;

            // 5. Проверка наличия спецсимволов
            // В задании (пункт 4.9) указан конкретный набор: #$%^&_
            // Метод Intersect находит пересечение символов пароля и спецсимволов.
            // Если количество пересечений 0, значит спецсимволов нет.
            if (password.Intersect("#$%^&_").Count() == 0)
                return false;

            // Если все проверки пройдены
            return true;
        }
    }
}