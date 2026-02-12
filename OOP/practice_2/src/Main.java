import java.util.ArrayList;
import java.util.List;

public class Main {
    public static void main(String[] args) {

        Car car = new Car("Tesla", 120.0);
        Bicycle bicycle = new Bicycle("BMX", 25.0);

        Vehicle train = new Vehicle() {
            @Override
            public void start() {
                System.out.println("Поезд отправляется");
            }

            @Override
            public void stop() {
                System.out.println("Поезд остановился");
            }

            @Override
            public double getSpeed() {
                return 100;
            }
        };

        
        Vehicle boat = new Vehicle() {
            @Override
            public void start() {
                System.out.println("Катер отчаливает");
            }

            @Override
            public void stop() {
                System.out.println("Катер пристает к берегу");
            }

            @Override
            public double getSpeed() {
                return 50;
            }
        };

        List<Vehicle> vehicles = new ArrayList<>();
        vehicles.add(car);
        vehicles.add(bicycle);
        vehicles.add(train);
        vehicles.add(boat);

        for (Vehicle v : vehicles) {
            System.out.println("----------------------------");
            v.start();
            v.stop();
            System.out.println("Скорость: " + v.getSpeed() + " км/ч");

            if (v instanceof ElectricVehicle ev) {
                // ElectricVehicle ev = (ElectricVehicle) v;
                ev.chargeBattery();
            }
        }
    }
}