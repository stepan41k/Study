import java.util.*;

class University {
    private String name;
    private List<Student> students = new ArrayList<>();
    
    public void addStudent(Student s) {
        students.add(s);
    }
    
    public void removeStudents(Student s) {
        students.remove(s);
    }
    
    public void printStudents() {
        for (Student student : students) {
            System.out.println(student.name);
        }
    }
}

class Student {
    String name;
    public Student(String name) {
        this.name = name;
    }
}

public class Main {
    public static void main(String[] args) {
        University university = new University();
            
        Student student = new Student("Igor");
        
        Student student2 = new Student("Victor");
        
        Student student3 = new Student("Pavel");
        
        university.addStudent(student);
        university.addStudent(student2);
        university.addStudent(student3);
        
        university.printStudents();
    }
}
