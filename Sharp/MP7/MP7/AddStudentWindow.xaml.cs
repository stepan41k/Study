using MP7;
using MP7.Models;
using System.Windows;

namespace MP7
{
    public partial class AddStudentWindow : Window
    {
        public AddStudentWindow()
        {
            InitializeComponent();
        }

        private void AddButton_Click(object sender, RoutedEventArgs e)
        {
            // Проверка, что все поля заполнены
            if (string.IsNullOrWhiteSpace(FirstNameTextBox.Text) ||
                string.IsNullOrWhiteSpace(LastNameTextBox.Text) ||
                string.IsNullOrWhiteSpace(GroupTextBox.Text))
            {
                MessageBox.Show("Пожалуйста, заполните обязательные поля: Имя, Фамилия, Группа.", "Ошибка валидации", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            // Создаем новый объект студента из данных в TextBox'ах
            var newStudent = new Student
            {
                FirstName = FirstNameTextBox.Text,
                LastName = LastNameTextBox.Text,
                Group = GroupTextBox.Text,
                Role = RoleTextBox.Text,
                Email = EmailTextBox.Text
            };

            // Создаем переменную контекста
            using (var context = new DatabaseContext())
            {
                // Добавляем нового студента в DbSet
                context.Students.Add(newStudent);
                // Сохраняем изменения в базе данных
                context.SaveChanges();
            }

            MessageBox.Show("Студент успешно добавлен!", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);

            // Устанавливаем DialogResult в true, чтобы главное окно знало об успехе
            this.DialogResult = true;
        }
    }
}