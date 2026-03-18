package unischedule.model;

public class Lecture extends Lesson {
    public Lecture(String subject, Teacher t, StudentGroup g, Classroom c, TimeSlot ts) {
        super(subject, t, g, c, ts);
    }
    @Override public String getLessonType() { return "Лекция"; }
}