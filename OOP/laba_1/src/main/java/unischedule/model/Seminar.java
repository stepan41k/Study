package unischedule.model;

public class Seminar extends Lesson {
    public Seminar(String subject, Teacher t, StudentGroup g, Classroom c, TimeSlot ts) { super(subject, t, g, c, ts); }
    @Override public String getLessonType() { return "Семинар"; }
}