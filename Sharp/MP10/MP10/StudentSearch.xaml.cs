using MP11.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using MessageBox = System.Windows.MessageBox;

namespace MP11
{
    public partial class StudentSearch : Page
    {
        public StudentSearch()
        {
            InitializeComponent();

            // Загрузка данных для ComboBox (4.4)
            LoadGroups();

            // 4.5. Задайте начальные значения
            CheckFilterGroup.IsChecked = false; // По умолчанию фильтр выключен
            ComboGroup.SelectedIndex = 0;       // Выбран пункт "Все группы"

            // Первичная загрузка списка
            UpdateStudent();
        }

        private void LoadGroups()
        {
            // Получаем уникальные группы из БД через Singleton контекст
            var groups = DatabaseContext.GetContext().Students
                .Select(s => s.Group)
                .Distinct()
                .OrderBy(g => g)
                .ToList();

            // Добавляем пункт "Все группы" в начало списка
            groups.Insert(0, "Все группы");

            ComboGroup.ItemsSource = groups;
        }

        // 4.6. Метод обновления данных с учетом поиска и фильтрации
        private void UpdateStudent()
        {
            // Берем всех студентов из контекста
            var currentStudents = DatabaseContext.GetContext().Students.ToList();

            // 1. Фильтрация по поиску (Фамилия) - если текст введен
            if (!string.IsNullOrWhiteSpace(TBoxSearch.Text))
            {
                currentStudents = currentStudents.Where(p =>
                    p.LastName.ToLower().Contains(TBoxSearch.Text.ToLower()) ||
                    p.FirstName.ToLower().Contains(TBoxSearch.Text.ToLower())
                ).ToList();
            }

            // 2. Фильтрация по группе (4.6.1)
            // Фильтруем ТОЛЬКО если стоит галочка CheckBox И выбрана конкретная группа (не "Все группы")
            if (CheckFilterGroup.IsChecked == true && ComboGroup.SelectedIndex > 0)
            {
                string selectedGroup = ComboGroup.SelectedItem as string;
                if (!string.IsNullOrEmpty(selectedGroup))
                {
                    currentStudents = currentStudents.Where(p => p.Group == selectedGroup).ToList();
                }
            }

            // Обновляем источник данных таблицы
            StudentsDataGrid.ItemsSource = currentStudents;
        }

        // Обработчик изменения текста поиска
        private void TBoxSearch_TextChanged(object sender, TextChangedEventArgs e)
        {
            UpdateStudent();
        }

        // Обработчик выбора в выпадающем списке
        private void ComboGroup_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            UpdateStudent();
        }

        // Обработчик установки галочки
        private void CheckFilterGroup_Checked(object sender, RoutedEventArgs e)
        {
            UpdateStudent();
        }

        // Обработчик снятия галочки
        private void CheckFilterGroup_Unchecked(object sender, RoutedEventArgs e)
        {
            UpdateStudent();
        }
    }
}