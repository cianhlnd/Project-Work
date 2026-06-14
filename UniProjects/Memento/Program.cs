//Tested on Windows 10 and VSCode Version: 1.73.1


using System;
using static System.Console;
using System.Collections.Generic;
using System.IO;

namespace CS264Assignment3
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.Clear();
            bool cont = true;
            string input = "";
            string svg = "";
            //create canvas list to store inputted shape
            List<Shape> canvas = new List<Shape>();
            //create caretake variable for undo and redo
            Caretaker undoRedo = new Caretaker();
            WriteLine("List of commands: ");
            WriteLine("A<shape>     Add shape to canvas");
            WriteLine("D            Display Canvas");
            WriteLine("S            Save Canvas");
            WriteLine("U            Undo last operation");
            WriteLine("R            Redo last operation");
            WriteLine("C            Clear canvas");
            WriteLine("Q            Quit");
            WriteLine("H            Help");
            while (cont)
            {
                //take in user input
                input = ReadLine();
                string shape = "";
                //split letter and shape if user wants to add shape
                if (input.Contains("A") || input.Contains("a"))
                {
                    shape = input.Substring(2);
                    input = input.Substring(0, 1).ToUpper();
                    shape = shape.Substring(0, 1).ToUpper() + shape.Substring(1).ToLower();
                } 
                else { input = input.ToUpper(); }
                //switch statement goes through each user input
                switch (input)
                {
                    //A - adding shape
                    case "A":
                        addShape(shape, canvas);
                        break;
                    //D - displays canvas
                    case "D":
                        WriteLine("Current Canvas:");
                        displayCanvas(canvas);
                        break;
                    case "S":
                        svg = createSVG(canvas);
                        WriteLine("File canvas.svg has been succesfully saved!");
                        File.WriteAllText("canvas.svg", svg);
                        break;
                    //U - undo shape
                    case "U":
                        //tell user that the canvas is empty
                        if(canvas.Count == 0) { WriteLine("Canvas is empty"); }
                        else { undoShapeCanvas(canvas, undoRedo); }
                        break;
                    //R - redo shape into canvas
                    case "R":
                        //tell user they can't redo anymore shapes
                        if (undoRedo.getSize() == 0) { WriteLine("No more shapes to redo"); }
                        else { redoShapeCanvas(canvas, undoRedo); }
                        break;
                    //C - clear canvas
                    case "C":
                        canvas.Clear();
                        undoRedo = new Caretaker();
                        WriteLine("canvas has been cleared");
                        break;
                    
                    //Q - quit the loop
                    case "Q":
                        WriteLine("Goodbye!");
                        cont = false;
                        break;
                    // displays Help
                    case "H":                       
                        WriteLine("Commands");
                        WriteLine("A <shape>        Add Shape");
                        WriteLine("C                Clear canvas");
                        WriteLine("D                Display canvas");
                        WriteLine("S                Save canvas");
                        WriteLine("H                Help");
                        WriteLine("Q                Quit Program");
                        WriteLine("R                Redo");
                        WriteLine("U                Undo");
                        break;
                    //tell the user that their input is invalid
                    default:
                        WriteLine("Invalid input");
                        break;
                }
                input = "";
            }
        }
        //creates svg layout from current shapes in canvas
        //return as string
        public static string createSVG(List<Shape> shape)
        {
            string beginning = "<svg width=\"1000\" height=\"1000\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\">";
            string middle = "";
            string end = "</svg>";
            foreach (Shape s in shape)
            {
                if (s.name.Equals("Rectangle")) { middle += "\n" + s.shapeCode(); }
                else if (s.name.Equals("Circle")) { middle += "\n" + s.shapeCode(); }
                else if (s.name.Equals("Ellipse")) { middle += "\n" + s.shapeCode(); }
                else if (s.name.Equals("Line")) { middle += "\n" + s.shapeCode(); }
                else if (s.name.Equals("Polyline")) { middle += "\n" + s.shapeCode(); }
                else if (s.name.Equals("Polygon")) { middle += "\n" + s.shapeCode(); }
            }
            return beginning + middle + "\n" + end;
        }
        //adds shapes to canvas
        public static void addShape(string s, List<Shape> canvas)
        {
            //use switch statement to add appropriate shape to canvas
            //use default ints for shapes
            //add shape into canvas
            Shape temp;
            switch (s)
            {
                case "Rectangle":
                    Rectangle rectangle = new Rectangle(100, 150, 50, 300);
                    temp = rectangle;
                    canvas.Add(temp);
                    WriteLine(temp.name + " (X=" + rectangle.x + ",Y=" + rectangle.y + ",H=" + rectangle.h + ",W=" + rectangle.w +  ") added to canvas.");
                    break;
                case "Circle":
                    Circle circle = new Circle(50, 200, 150);
                    temp = circle;
                    canvas.Add(temp);
                    WriteLine(temp.name + " (R=" + circle.radius + ",X=" + circle.cx + ",Y=" + circle.cy + ") added to canvas.");
                    break;
                case "Ellipse":
                    Ellipse ellipse = new Ellipse(150, 100, 260, 100);
                    temp = ellipse;
                    canvas.Add(temp);
                    WriteLine(temp.name + " (RX=" + ellipse.rx + ",RY=" + ellipse.rx + ",CX=" + ellipse.cy + ",CY= " + ellipse.cy + ") added to canvas.");
                    break;
                case "Line":
                    Line line = new Line(150, 225, 150, 50);
                    temp = line;
                    canvas.Add(temp);
                    WriteLine(temp.name + " (X1=" + line.x1 + ",X2=" + line.x2 + ",Y1=" + line.y1 + ",Y2=" + line.x2 + ") added to canvas.");
                    break;
                case "Polyline":
                    Polyline polyline = new Polyline("0,100 50,25 50,75 100,0");
                    temp = polyline;
                    canvas.Add(temp);
                    WriteLine(temp.name + " (Co-ordinates=" + polyline.coord + ") added to canvas.");
                    break;
                case "Polygon":
                    Polygon polygon = new Polygon("100,100 150,25 150,75 200,0");
                    temp = polygon;
                    canvas.Add(temp);
                    WriteLine(temp.name + " (Co-ordinates=" + polygon.coord + ") added to canvas.");
                    break;
                default:
                    WriteLine("Invalid shape input");
                    WriteLine("List of valid shapes: \n ->Rectangle \n ->Circle \n ->Ellispe \n ->Line \n ->Polyline \n ->Polygon");
                    break;
            }
        }
        //displays current canvas
        static void displayCanvas(List<Shape> canvas)
        {
            String SVG = createSVG(canvas);
            WriteLine(SVG);
        }
        //undo method
        static void undoShapeCanvas(List<Shape> canvas, Caretaker undoRedo)
        {
            //create memento state
            Memento state = new Memento();
            //create shape variable and store last shape in canvas
            Shape shape = canvas[canvas.Count - 1];
            //set the state to the last shape
            state.setShape(shape);
            //remove shape in cavas
            canvas.Remove(shape);
            //then add that state to the caretaker
            undoRedo.addState(state);
            WriteLine(shape.name + " has been removed from the canvas");
        }
        //redo method
        static void redoShapeCanvas(List<Shape> canvas, Caretaker undoRedo)
        {
            //create memento variable and get last state in caretaker
            Memento state = undoRedo.getState();
            //create shape variable and store the state
            Shape shape = state.getShape();
            //add shape in the canvas
            canvas.Add(shape);
            WriteLine(shape.name + " has been added back to the canvas");
        }
    }
    //create parent class Shape
    //then there are indvidual classes for each shape
    //shapeCode() method returns the svg line of each shape
    abstract class Shape
    {
        //shape class variables
        public string name { get; set; }
        public int strokeWidth { get; set; }
        public string stroke { get; set; }
        public string fill { get; set; }
        public virtual string shapeCode() { return ""; }
    }
    class Rectangle : Shape
    {
        public int x { get; set; }
        public int y { get; set; }
        public int w { get; set; }
        public int h { get; set; }
        public Rectangle(int x, int y, int w, int h)
        {
            this.name = "Rectangle";
            this.x = x;
            this.y = y;
            this.h = h;
            this.w = w;
            this.stroke = "black";
            this.strokeWidth = 1;
            this.fill = "grey";
        }
        public override string shapeCode()
        {
            return "    <rect x=\"" + this.x + "\" y=\"" + this.y + "\" width=\"" + this.w + "\" height=\"" + this.h + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
    }
    class Circle : Shape
    {
        public int cx { get; set; }
        public int cy { get; set; }
        public int radius { get; set; }
        public Circle (int x, int y, int r)
        {
            this.name = "Circle";
            this.radius = r;
            this.cx = x;
            this.cy = y;
            this.stroke = "black";
            this.strokeWidth = 1;
            this.fill = "grey";
        }
        public override string shapeCode()
        {
            return "    <circle cx=\"" + this.cx + "\" cy=\"" + this.cy + "\" r=\"" + this.radius + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
    }
    class Ellipse : Shape
    {
        public int cx { get; set; }
        public int cy { get; set; }
        public int rx { get; set; }
        public int ry { get; set; }
        public Ellipse(int x, int y, int r1, int r2)
        {
            this.name = "Ellipse";
            this.cx = x;
            this.cy = y;
            this.rx = r1;
            this.ry = r2;
            this.strokeWidth = 1;
            this.stroke = "black";
            this.fill = "grey";
        }
        public override string shapeCode()
        {
            return "    <ellipse cx=\"" + this.cx + "\" cy=\"" + this.cy + "\" rx=\"" + this.rx + "\" ry=\"" + this.ry + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
    }
    class Line : Shape
    {
        public int x1 { get; set; }
        public int y1 { get; set; }
        public int x2 { get; set; }
        public int y2 { get; set; }
        public Line(int x, int y, int a, int b)
        {
            this.name = "Line";
            this.x1 = x;
            this.y1 = y;
            this.x2 = a;
            this.y2 = b;
            this.strokeWidth = 1;
            this.stroke = "black";
            this.fill = "grey";
        }
        public override string shapeCode()
        {
            return "    <line x1=\"" + this.x1 + "\" y1=\"" + this.y1 + "\" x2=\"" + this.x2 + "\" y2=\"" + this.y2 + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
    }
    class Polyline : Shape
    {
        public string coord { get; set; }
        public Polyline(string s)
        {
            this.name = "Polyline";
            this.coord = s;
            this.strokeWidth = 1;
            this.stroke = "black";
            this.fill = "grey";
        }
        public override string shapeCode()
        {
            return "    <polyline fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\" points=\"" + this.coord + "\"/>";
        }
    }
    class Polygon : Shape
    {
        public string coord { get; set; }
        public Polygon(string s)
        {
            this.name = "Polygon";
            this.coord = s;
            this.strokeWidth = 1;
            this.stroke = "black";
            this.fill = "grey";
        }
        public override string shapeCode()
        {
            return "    <polygon fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\" points=\"" + this.coord + "\"/>";
        }
    }
    class Path : Shape
    {
        public string coord { get; set; }
        public Path(string s)
        {
            this.name = "Path";
            this.coord = s;
            this.strokeWidth = 1;
            this.stroke = "black";
            this.fill = "grey";
        }
        public override string shapeCode()
        {
            return "    <path fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\" d=\"" + this.coord + "\"/>";
        }
    }
    //I am using the Memento Design Pattern
    class Memento
    {
        Shape shape;
        public Shape getShape()
        {
            return this.shape;
        }
        public void setShape(Shape s)
        {
            this.shape = s;
        }
    }
    //caretaker is used to store memento
    class Caretaker
    {
        List<Memento> undoRedo = new List<Memento>();
        Memento state = new Memento();
        public Memento getState()
        {
            this.state = this.undoRedo[undoRedo.Count-1];
            this.undoRedo.RemoveAt(undoRedo.Count - 1);
            return this.state;
        }
        public void addState(Memento m)
        {
            this.state = m;
            this.undoRedo.Add(state);
        }
        public int getSize() { return this.undoRedo.Count; }
    }
}
