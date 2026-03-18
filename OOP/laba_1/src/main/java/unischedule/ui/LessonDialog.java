package unischedule.ui;

import unischedule.logic.ConflictException;
import unischedule.logic.ScheduleManager;
import unischedule.model.*;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;

/**
 * Диалоговое окно для создания нового занятия.
 * Реализует логику сбора данных и вызова проверки конфликтов.
 */
public class LessonDialog extends JDialog {
    private final ScheduleManager manager;
    private final MainFrame parentFrame;

    // Компоненты формы
    private JTextField txtSubject;
    private JComboBox<String> comboType;
    private JComboBox<Teacher> comboTeacher;
    private JComboBox<StudentGroup> comboGroup;
    private JComboBox<Classroom> comboRoom;
    private JComboBox<String> comboDay;
    private JComboBox<Integer> comboSlot;

    public LessonDialog(MainFrame owner, ScheduleManager manager) {
        super(owner, "Добавление занятия", true); // true = модальное окно
        this.parentFrame = owner;
        this.manager = manager;

        initUI();
    }

    private void initUI() {
        setLayout(new BorderLayout());
        setSize(450, 450);
        setLocationRelativeTo(parentFrame);

        // Панель формы с полями ввода
        JPanel formPanel = new JPanel(new GridLayout(7, 2, 10, 15));
        formPanel.setBorder(new EmptyBorder(20, 20, 20, 20));

        // 1. Предмет
        formPanel.add(new JLabel("Название дисциплины:"));
        txtSubject = new JTextField();
        formPanel.add(txtSubject);

        // 2. Тип занятия (Демонстрация полиморфизма)
        formPanel.add(new JLabel("Тип занятия:"));
        comboType = new JComboBox<>(new String[]{"Лекция", "Семинар"});
        formPanel.add(comboType);

        // 3. Преподаватель (Берем список из менеджера)
        formPanel.add(new JLabel("Преподаватель:"));
        comboTeacher = new JComboBox<>(manager.getTeachers().toArray(new Teacher[0]));
        formPanel.add(comboTeacher);

        // 4. Группа
        formPanel.add(new JLabel("Учебная группа:"));
        comboGroup = new JComboBox<>(manager.getGroups().toArray(new StudentGroup[0]));
        formPanel.add(comboGroup);

        // 5. Аудитория
        formPanel.add(new JLabel("Аудитория:"));
        comboRoom = new JComboBox<>(manager.getClassrooms().toArray(new Classroom[0]));
        formPanel.add(comboRoom);

        // 6. День недели
        formPanel.add(new JLabel("День недели:"));
        comboDay = new JComboBox<>(new String[]{"Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"});
        formPanel.add(comboDay);

        // 7. Номер пары
        formPanel.add(new JLabel("Номер пары (время):"));
        comboSlot = new JComboBox<>(new Integer[]{1, 2, 3, 4, 5, 6});
        formPanel.add(comboSlot);

        add(formPanel, BorderLayout.CENTER);

        // Панель кнопок
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.setBorder(new EmptyBorder(0, 0, 15, 15));

        JButton btnCancel = new JButton("Отмена");
        JButton btnSave = new JButton("Сохранить");
        btnSave.setFont(new Font("SansSerif", Font.BOLD, 12));

        btnCancel.addActionListener(e -> dispose());
        btnSave.addActionListener(e -> handleSave());

        buttonPanel.add(btnCancel);
        buttonPanel.add(btnSave);
        add(buttonPanel, BorderLayout.SOUTH);
    }

    /**
     * Логика сохранения занятия с проверкой на конфликты.
     */
    private void handleSave() {
        String subject = txtSubject.getText().trim();
        
        // Валидация пустого ввода
        if (subject.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Введите название предмета!", "Ошибка", JOptionPane.WARNING_MESSAGE);
            return;
        }

        // Получение выбранных данных
        String type = (String) comboType.getSelectedItem();
        Teacher teacher = (Teacher) comboTeacher.getSelectedItem();
        StudentGroup group = (StudentGroup) comboGroup.getSelectedItem();
        Classroom room = (Classroom) comboRoom.getSelectedItem();
        String day = (String) comboDay.getSelectedItem();
        Integer slotNumber = (Integer) comboSlot.getSelectedItem();

        // Создание объекта времени
        TimeSlot timeSlot = new TimeSlot(day, slotNumber);

        // Использование полиморфизма при создании объекта Lesson
        Lesson newLesson;
        if ("Лекция".equals(type)) {
            newLesson = new Lecture(subject, teacher, group, room, timeSlot);
        } else {
            newLesson = new Seminar(subject, teacher, group, room, timeSlot);
        }

        try {
            // Пытаемся добавить занятие через бизнес-логику
            manager.addLesson(newLesson);
            
            // Если конфликтов нет — закрываем окно
            dispose();
        } catch (ConflictException ex) {
            // Вывод сообщения об ошибке (Требование №8)
            JOptionPane.showMessageDialog(
                this, 
                "Невозможно добавить занятие:\n" + ex.getMessage(), 
                "Конфликт расписания", 
                JOptionPane.ERROR_MESSAGE
            );
        }
    }
}