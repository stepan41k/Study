using MP11;
using MP11.Models;
using System.Linq;
using System.Windows;
using MessageBox = System.Windows.MessageBox;

namespace MP11
{
    public partial class DeleteStudentWindow : Window
    {
        // Поле для хранения студента, которого нужно удалить
        private Student _studentToDelete;

        // Конструктор теперь принимает объект Student
        public DeleteStudentWindow(Student studentToDelete)
        {
            InitializeComponent();
            _studentToDelete = studentToDelete;
            // Заполняем поля данными полученного студента
            LoadStudentData();
        }

        // Метод для заполнения полей
        private void LoadStudentData()
        {
            FirstNameTextBox.Text = _studentToDelete.FirstName;
            LastNameTextBox.Text = _studentToDelete.LastName;
            GroupTextBox.Text = _studentToDelete.Group;
        }

        private void DeleteButton_Click(object sender, RoutedEventArgs e)
        {
            // Спрашиваем подтверждение
            MessageBoxResult result = MessageBox.Show(
                $"Вы уверены, что хотите удалить студента: {_studentToDelete.FirstName} {_studentToDelete.LastName}?",
                "Подтверждение удаления",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

            if (result == MessageBoxResult.No)
            {
                return; // Если пользователь нажал "Нет", ничего не делаем
            }

            using (var context = new DatabaseContext())
            {
                // Прикрепляем объект к контексту и помечаем его как удаленный
                context.Students.Remove(_studentToDelete);
                // Сохраняем изменения в БД
                context.SaveChanges();
            }

            MessageBox.Show("Студент успешно удален.", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
            this.DialogResult = true; // Сообщаем главному окну об успехе
        }
    }
}