using MP11;
using MP11.Pages;
using System.Linq;
using System.Windows;
using MessageBox = System.Windows.MessageBox;
using System.Windows.Controls;

namespace MP11.Pages // Замените WpfAppExample на имя вашего проекта
{
    public partial class Authorization : Page
    {
        private DatabaseContext _dbContext;

        public Authorization()
        {
            InitializeComponent();
            _dbContext = new DatabaseContext();
        }

        private void BtnAuthorization_Click(object sender, RoutedEventArgs e)
        {
            string username = UsernameTextBox.Text;
            string password = PasswordBox.Password;

            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                MessageBox.Show("Пожалуйста, заполните все поля.");
                return;
            }

            // Ищем пользователя в базе данных
            var user = _dbContext.Users.FirstOrDefault(u => u.Username == username && u.Password == password);

            if (user != null)
            {
                MessageBox.Show($"Добро пожаловать, {user.FullName}!");
                // Здесь можно реализовать переход на главную страницу после успешного входа
            }
            else
            {
                MessageBox.Show("Неверное имя пользователя или пароль.");
            }
        }

        private void BtnGoToRegistration_Click(object sender, RoutedEventArgs e)
        {
            // Переход на страницу регистрации
            this.NavigationService.Navigate(new Registration());
        }
    }
}