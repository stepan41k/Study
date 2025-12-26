using MP6_2;
using MP6_2.Models;
using System.Linq;
using System.Windows;
using System.Windows.Controls;

namespace MP6_2.Pages;

public partial class Registration : Page
{
    private readonly DatabaseContext _dbContext;

    public Registration()
    {
        InitializeComponent();
        _dbContext = new DatabaseContext();
    }

    private void BtnRegister_Click(object sender, RoutedEventArgs e)
    {
        string fullName = FullNameTextBox.Text;
        string username = UsernameTextBox.Text;
        string password = PasswordBox.Password;
        string confirmPassword = ConfirmPasswordBox.Password;

        // Проверки
        if (string.IsNullOrWhiteSpace(fullName) || string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(confirmPassword))
        {
            MessageBox.Show("Все поля должны быть заполнены.");
            return;
        }

        if (password != confirmPassword)
        {
            MessageBox.Show("Пароли не совпадают.");
            return;
        }

        // Проверка, существует ли пользователь с таким именем
        if (_dbContext.Users.Any(u => u.Username == username))
        {
            MessageBox.Show("Пользователь с таким именем уже существует.");
            return;
        }

        // Создание нового пользователя
        var newUser = new User
        {
            FullName = fullName,
            Username = username,
            Password = password // В реальном приложении пароли нужно хешировать!
        };

        // Добавление в базу данных
        _dbContext.Users.Add(newUser);
        _dbContext.SaveChanges();

        MessageBox.Show("Регистрация прошла успешно!");

        // Переход на страницу авторизации после успешной регистрации
        this.NavigationService.Navigate(new Authorization());
    }

    private void BtnGoToAuthorization_Click(object sender, RoutedEventArgs e)
    {
        this.NavigationService.Navigate(new Authorization());
    }
}