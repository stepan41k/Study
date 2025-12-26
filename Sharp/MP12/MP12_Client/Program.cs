using MP12_Client;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

class Program
{
    // Пункты 4.20: Настройка клиента
    private static readonly HttpClient client = new HttpClient();
    // Убедитесь, что порт (5000, 5271 и т.д.) совпадает с тем, на котором запустился ваш сервер!
    private static readonly string baseUrl = "https://localhost:7270/api/Student";

    static async Task Main(string[] args)
    {
        Console.WriteLine("Запуск клиента...");

        // Задержка, чтобы сервер успел подняться, если запускаете вместе
        await Task.Delay(2000);

        bool exit = false;
        while (!exit)
        {
            Console.WriteLine("\n--- МЕНЮ ---");
            Console.WriteLine("1. Получить всех студентов");
            Console.WriteLine("2. Получить студента по ID");
            Console.WriteLine("3. Создать студента");
            Console.WriteLine("4. Обновить студента");
            Console.WriteLine("5. Удалить студента");
            Console.WriteLine("0. Выход");
            Console.Write("Выберите действие: ");

            var choice = Console.ReadLine();

            switch (choice)
            {
                case "1":
                    await GetAllStudents();
                    break;
                case "2":
                    await GetStudentById();
                    break;
                case "3":
                    await CreateStudent();
                    break;
                case "4":
                    await UpdateStudent();
                    break;
                case "5":
                    await DeleteStudent();
                    break;
                case "0":
                    exit = true;
                    break;
                default:
                    Console.WriteLine("Неверный ввод.");
                    break;
            }
        }
    }

    // Пункт 4.21: Получение всех студентов
    private static async Task GetAllStudents()
    {
        Console.WriteLine("\nПолучение списка студентов...");
        try
        {
            var students = await client.GetFromJsonAsync<List<Student>>(baseUrl);
            if (students != null)
            {
                foreach (var s in students)
                {
                    Console.WriteLine(s.ToString());
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Ошибка: {ex.Message}");
        }
    }

    // Пункт 4.22: Получение по ID
    private static async Task GetStudentById()
    {
        Console.Write("\nВведите ID студента: ");
        if (int.TryParse(Console.ReadLine(), out int id))
        {
            try
            {
                var student = await client.GetFromJsonAsync<Student>($"{baseUrl}/{id}");
                if (student != null)
                {
                    Console.WriteLine($"Найден: {student}");
                }
            }
            catch (HttpRequestException)
            {
                Console.WriteLine("Студент не найден (404).");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
        }
    }

    private static async Task CreateStudent()
    {
        Console.WriteLine("\n--- Добавление студента ---");
        var newStudent = new Student();

        // Если ID в БД Serial (автоинкремент), то эту строчку можно убрать или вводить 0
        Console.Write("Id (если автоинкремент - введите 0): ");
        newStudent.Id = int.Parse(Console.ReadLine() ?? "0");

        Console.Write("Фамилия (LastName): ");
        newStudent.LastName = Console.ReadLine();

        Console.Write("Имя (FirstName): ");
        newStudent.FirstName = Console.ReadLine();

        Console.Write("Роль (Role): ");
        newStudent.Role = Console.ReadLine(); // например "студент"

        Console.Write("Email: ");
        newStudent.Email = Console.ReadLine();

        Console.Write("Группа (Group): ");
        newStudent.Group = Console.ReadLine();

        var response = await client.PostAsJsonAsync(baseUrl, newStudent);
        Console.WriteLine($"Статус: {response.StatusCode}");
    }

    // Изменяем метод обновления:
    private static async Task UpdateStudent()
    {
        Console.Write("Введите ID для редактирования: ");
        if (int.TryParse(Console.ReadLine(), out int id))
        {
            var existing = await client.GetFromJsonAsync<Student>($"{baseUrl}/{id}");
            if (existing == null) { Console.WriteLine("Не найден."); return; }

            Console.WriteLine($"Меняем: {existing}");
            Console.WriteLine("Жмите Enter, чтобы оставить старое значение.");

            Console.Write($"Фамилия ({existing.LastName}): ");
            var ln = Console.ReadLine();
            if (!string.IsNullOrWhiteSpace(ln)) existing.LastName = ln;

            Console.Write($"Имя ({existing.FirstName}): ");
            var fn = Console.ReadLine();
            if (!string.IsNullOrWhiteSpace(fn)) existing.FirstName = fn;

            Console.Write($"Роль ({existing.Role}): ");
            var role = Console.ReadLine();
            if (!string.IsNullOrWhiteSpace(role)) existing.Role = role;

            Console.Write($"Email ({existing.Email}): ");
            var mail = Console.ReadLine();
            if (!string.IsNullOrWhiteSpace(mail)) existing.Email = mail;

            Console.Write($"Группа ({existing.Group}): ");
            var gr = Console.ReadLine();
            if (!string.IsNullOrWhiteSpace(gr)) existing.Group = gr;

            var response = await client.PutAsJsonAsync($"{baseUrl}/{id}", existing);
            Console.WriteLine($"Результат: {response.StatusCode}");
        }
    }

    // Пункт 4.24: Удаление (разработано по аналогии)
    private static async Task DeleteStudent()
    {
        Console.WriteLine("\n--- Удаление студента ---");
        Console.Write("Введите ID студента для удаления: ");
        if (int.TryParse(Console.ReadLine(), out int id))
        {
            var response = await client.DeleteAsync($"{baseUrl}/{id}");

            if (response.IsSuccessStatusCode)
            {
                Console.WriteLine("Студент удален.");
            }
            else
            {
                Console.WriteLine($"Ошибка при удалении. Статус: {response.StatusCode}");
            }
        }
    }
}