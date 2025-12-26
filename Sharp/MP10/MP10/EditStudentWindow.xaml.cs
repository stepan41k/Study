using MP11;
using MP11.Models;
using System.Linq;
using MessageBox = System.Windows.MessageBox;
using System.Windows;

namespace MP11
{
    public partial class EditStudentWindow : Window
    {
        private Student _studentToEdit;

        public EditStudentWindow(Student studentToEdit)
        {
            InitializeComponent();
            _studentToEdit = studentToEdit;
            LoadStudentData();
        }

        private void LoadStudentData()
        {
            FirstNameTextBox.Text = _studentToEdit.FirstName;
            LastNameTextBox.Text = _studentToEdit.LastName;
            GroupTextBox.Text = _studentToEdit.Group;
            RoleTextBox.Text = _studentToEdit.Role;
            EmailTextBox.Text = _studentToEdit.Email;
        }

        private void SaveButton_Click(object sender, RoutedEventArgs e)
        {
            // Валидация
            if (string.IsNullOrWhiteSpace(FirstNameTextBox.Text) || string.IsNullOrWhiteSpace(LastNameTextBox.Text))
            {
                MessageBox.Show("Имя и Фамилия не могут быть пустыми.", "Ошибка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            using (var context = new DatabaseContext())
            {
                // Находим студента в базе данных по его Id
                var studentInDb = context.Students.Find(_studentToEdit.Id);

                if (studentInDb != null)
                {
                    // Обновляем его свойства значениями из текстовых полей
                    studentInDb.FirstName = FirstNameTextBox.Text;
                    studentInDb.LastName = LastNameTextBox.Text;
                    studentInDb.Group = GroupTextBox.Text;
                    studentInDb.Role = RoleTextBox.Text;
                    studentInDb.Email = EmailTextBox.Text;

                    // Сохраняем изменения
                    context.SaveChanges();
                }
            }

            MessageBox.Show("Данные студента успешно обновлены.", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
            this.DialogResult = true;
        }
    }
}