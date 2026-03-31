package unischedule.ui;

import java.awt.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import javax.swing.*;
import javax.swing.border.EmptyBorder;
import unischedule.logic.*;
import unischedule.model.*;

public class LessonDialog extends JDialog {

    private final ScheduleManager manager;
    private final MainFrame parentFrame;
    private final int editIndex;

    private JTextField txtSubject;
    private JComboBox<String> comboType;
    private JComboBox<Teacher> comboTeacher;
    private JComboBox<StudentGroup> comboGroup;
    private JComboBox<Classroom> comboRoom;
    private JComboBox<String> comboDay;

    private JList<String> listTime;
    private JTextField txtComment;

    public LessonDialog(MainFrame owner, ScheduleManager manager) {
        this(owner, manager, null, -1);
    }

    public LessonDialog(
        MainFrame owner,
        ScheduleManager manager,
        Lesson existingLesson,
        int index
    ) {
        super(
            owner,
            (index == -1 ? "Добавление" : "Редактирование") + " занятия",
            true
        );
        this.parentFrame = owner;
        this.manager = manager;
        this.editIndex = index;

        initUI();

        if (existingLesson != null) {
            fillFields(existingLesson);
        }
    }

    private void fillFields(Lesson lesson) {
        txtSubject.setText(lesson.getSubject());
        comboType.setSelectedItem(lesson.getLessonType());
        comboTeacher.setSelectedItem(lesson.getTeacher());
        comboGroup.setSelectedItem(lesson.getGroup());
        comboRoom.setSelectedItem(lesson.getClassroom());
        comboDay.setSelectedItem(lesson.getTimeSlot().getDay());

        // Выделяем несколько часов в списке
        java.util.List<String> times = lesson.getTimeSlot().getStartTimes();
        int[] indices = new int[times.size()];
        ListModel<String> model = listTime.getModel();
        for (int i = 0; i < times.size(); i++) {
            for (int j = 0; j < model.getSize(); j++) {
                if (model.getElementAt(j).equals(times.get(i))) {
                    indices[i] = j;
                }
            }
        }
        listTime.setSelectedIndices(indices);
        txtComment.setText(lesson.getComment());
    }

    private void initUI() {
        setLayout(new BorderLayout());
        setSize(550, 500);
        setLocationRelativeTo(parentFrame);

        JPanel formPanel = new JPanel(new GridLayout(8, 2, 10, 10));
        formPanel.setBorder(new EmptyBorder(20, 20, 20, 20));

        formPanel.add(new JLabel("Название дисциплины:"));
        txtSubject = new JTextField();
        formPanel.add(txtSubject);

        formPanel.add(new JLabel("Тип занятия:"));
        comboType = new JComboBox<>(
            new String[] { "Лекция", "Практика", "Лабораторная" }
        );
        formPanel.add(comboType);

        formPanel.add(new JLabel("Преподаватель:"));
        comboTeacher = new JComboBox<>(
            manager.getTeachers().toArray(new Teacher[0])
        );
        formPanel.add(comboTeacher);

        formPanel.add(new JLabel("Учебная группа:"));
        comboGroup = new JComboBox<>(
            manager.getGroups().toArray(new StudentGroup[0])
        );
        formPanel.add(comboGroup);

        formPanel.add(new JLabel("Аудитория:"));
        comboRoom = new JComboBox<>(
            manager.getClassrooms().toArray(new Classroom[0])
        );
        formPanel.add(comboRoom);

        formPanel.add(new JLabel("День недели:"));
        comboDay = new JComboBox<>(
            new String[] {
                "Понедельник",
                "Вторник",
                "Среда",
                "Четверг",
                "Пятница",
                "Суббота",
            }
        );
        formPanel.add(comboDay);

        // 7. Время начала
        formPanel.add(new JLabel("Выберите время:"));
        String[] hours = {
            "09:00",
            "10:00",
            "11:00",
            "12:00",
            "13:00",
            "14:00",
            "15:00",
            "16:00",
            "17:00",
            "18:00",
            "19:00",
            "20:00",
            "21:00",
        };
        listTime = new JList<>(hours);
        listTime.setSelectionMode(
            ListSelectionModel.MULTIPLE_INTERVAL_SELECTION
        );
        formPanel.add(new JScrollPane(listTime));

        formPanel.add(new JLabel("Комментарий:"));
        txtComment = new JTextField();
        formPanel.add(txtComment);

        add(formPanel, BorderLayout.CENTER);

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.setBorder(new EmptyBorder(0, 0, 15, 15));
        JButton btnCancel = new JButton("Отмена");
        JButton btnSave = new JButton("Сохранить");

        btnCancel.addActionListener(e -> dispose());
        btnSave.addActionListener(e -> handleSave());

        buttonPanel.add(btnCancel);
        buttonPanel.add(btnSave);
        add(buttonPanel, BorderLayout.SOUTH);
    }


    private LocalDate getDateFromDayName(String dayName) {
        java.time.DayOfWeek targetDay;
        switch (dayName) {
            case "Понедельник":
                targetDay = java.time.DayOfWeek.MONDAY;
                break;
            case "Вторник":
                targetDay = java.time.DayOfWeek.TUESDAY;
                break;
            case "Среда":
                targetDay = java.time.DayOfWeek.WEDNESDAY;
                break;
            case "Четверг":
                targetDay = java.time.DayOfWeek.THURSDAY;
                break;
            case "Пятница":
                targetDay = java.time.DayOfWeek.FRIDAY;
                break;
            case "Суббота":
                targetDay = java.time.DayOfWeek.SATURDAY;
                break;
            default:
                targetDay = java.time.DayOfWeek.MONDAY;
        }
        return LocalDate.now().with(
            java.time.temporal.TemporalAdjusters.nextOrSame(targetDay)
        );
    }

    private void handleSave() {
        String subject = txtSubject.getText().trim();
        if (subject.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Введите название дисциплины!");
            return;
        }
    
        java.util.List<String> selectedTimes = listTime.getSelectedValuesList();
        if (selectedTimes.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Выберите хотя бы один час занятия (используйте Ctrl для выбора нескольких)!");
            return;
        }
    
        String type = (String) comboType.getSelectedItem();
        Teacher teacher = (Teacher) comboTeacher.getSelectedItem();
        StudentGroup group = (StudentGroup) comboGroup.getSelectedItem();
        Classroom room = (Classroom) comboRoom.getSelectedItem();
        String dayName = (String) comboDay.getSelectedItem();
    
        LocalDate date = getDateFromDayName(dayName);
    
        TimeSlot ts = new TimeSlot(dayName, selectedTimes);
        
        Lesson newLesson;
        if ("Лекция".equals(type)) {
            newLesson = new Lecture(subject, teacher, group, room, ts, date);
        } else if ("Практика".equals(type)) {
            newLesson = new Practice(subject, teacher, group, room, ts, date);
        } else {
            newLesson = new Labaratory(subject, teacher, group, room, ts, date);
        }
        
        newLesson.setComment(txtComment.getText().trim());
    
        try {
            if (editIndex == -1) {
                manager.addLesson(newLesson);
            } else {
                manager.updateLesson(editIndex, newLesson);
            }
            
            parentFrame.refreshTable();
            dispose();
        } catch (ConflictException ex) {
            JOptionPane.showMessageDialog(this, ex.getMessage(), "Конфликт", JOptionPane.ERROR_MESSAGE);
        }
    }
}
