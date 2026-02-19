//Tested on Windows 10 and VSCode Version: 1.73.1

using System;
using System.Collections.Generic;
using static System.Console;


namespace MyCommand
{

    class Program
    {
        // The Canvas (Receiver) class - holds a list of shapes 
        
        // Push and pops are involves in both Add and Remove classes
        public class Canvas
        {
            // Using stack to store canvas here
            private Stack<Shape> canvas = new Stack<Shape>();

            public void Add(Shape s)
            {
                canvas.Push(s);
                Console.WriteLine("Added Shape to canvas: {0}" + Environment.NewLine, s);
            }
            public Shape Remove()
            {
                Shape s = canvas.Pop();
                Console.WriteLine("Removed Shape from canvas: {0}" + Environment.NewLine, s);
                return s;
            }

            public Canvas()
            {
                Console.WriteLine("\nCreated a new Canvas!"); Console.WriteLine();
            }
            
            // Creates template to store Shape co-ordinates
            public override string ToString()
            {
                String str = "";
                foreach (Shape s in canvas)
                {
                    str = s + Environment.NewLine;
                }
                return str;
            }
        }

        // Abstract Shape class 
        public abstract class Shape
        {
            public string? name { get; set; }
            public int strokeWidth { get; set; }
            public string? stroke { get; set; }
            public string? fill { get; set; }
            public override string ToString() {return "No Shapes Found";}
        }

        // Rectangle Shape class
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
        public override string ToString()
        {
            return "    <rect x=\"" + this.x + "\" y=\"" + this.y + "\" width=\"" + this.w + "\" height=\"" + this.h + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
    }
    // Circle Shape class
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
        public override string ToString()
        {
            return "    <circle cx=\"" + this.cx + "\" cy=\"" + this.cy + "\" r=\"" + this.radius + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
    }
    // Ellipse Shape class
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
        public override string ToString()
        {
            return "    <ellipse cx=\"" + this.cx + "\" cy=\"" + this.cy + "\" rx=\"" + this.rx + "\" ry=\"" + this.ry + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
    }
    // Line Shape class
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
        public override string ToString()
        {
            return "    <line x1=\"" + this.x1 + "\" y1=\"" + this.y1 + "\" x2=\"" + this.x2 + "\" y2=\"" + this.y2 + "\" fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\"/>";
        }
    }
    // Polyline Shape class
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
        public override string ToString()
        {
            return "    <polyline fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\" points=\"" + this.coord + "\"/>";
        }
    }
    // Polygon Shape class
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
        public override string ToString()
        {
            return "    <polygon fill=\"" + this.fill + "\" stroke=\"" + this.stroke + "\" stroke-width=\"" + this.strokeWidth + "\" points=\"" + this.coord + "\"/>";
        }
    }
    public static void addShape(string s, Canvas canvas, User user)
        {
            //use switch statement to add appropriate shape to canvas
            //use random ints for shapes
            //adds shapes into canvas
            Random rnd = new Random();
            Shape temp;
            switch (s)
            {
                case "Rectangle":
                    user.Action(new AddShapeCommand(new Rectangle(rnd.Next(1, 1000), rnd.Next(1, 1000), rnd.Next(1, 1000), rnd.Next(1, 1000)), canvas));
                    break;
                case "Circle":
                    user.Action(new AddShapeCommand(new Circle(rnd.Next(1, 1000), rnd.Next(1, 1000), rnd.Next(1, 1000)), canvas));
                    break;
                case "Ellipse":
                    user.Action(new AddShapeCommand(new Ellipse(rnd.Next(1, 1000), rnd.Next(1, 1000), rnd.Next(1, 1000), rnd.Next(1,1000)), canvas));
                    break;
                case "Line":
                    user.Action(new AddShapeCommand(new Line(rnd.Next(1, 1000), rnd.Next(1, 1000), rnd.Next(1, 1000), rnd.Next(1,1000)), canvas));
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
        
        // The User (Invoker) Class
        public class User
        {
            private Stack<Command> undo;
            private Stack<Command> redo;

            public int UndoCount { get => undo.Count; }
            public int RedoCount { get => redo.Count; }
            public User()
            {
                Reset();
                Console.WriteLine("Created a new User!"); Console.WriteLine();
            }
            public void Reset()
            {
                undo = new Stack<Command>();
                redo = new Stack<Command>();
            }

            public void Action(Command command)
            {
                // first update the undo - redo stacks
                undo.Push(command);  // save the command to the undo command
                redo.Clear();        // once a new command is issued, the redo stack clears

                // next determine  action from the Command object type
                // this is going to be AddShapeCommand or DeleteShapeCommand
                Type t = command.GetType();
                if (t.Equals(typeof(AddShapeCommand)))
                {
                    Console.WriteLine("Command Received: Add new Shape!" + Environment.NewLine);
                    command.Do();
                }
            }

            // Undo
            public void Undo()
            {
                Console.WriteLine("Undoing operation!"); Console.WriteLine();
                if (undo.Count > 0)
                {
                    Command c = undo.Pop(); c.Undo(); redo.Push(c);
                }
            }

            // Redo
            public void Redo()
            {
                Console.WriteLine("Redoing operation!"); Console.WriteLine();
                if (redo.Count > 0)
                {
                    Command c = redo.Pop(); c.Do(); undo.Push(c);
                }
            }

        }

        // Abstract Command (Command) class - commands can do something and also undo
        public abstract class Command
        {
            public abstract void Do();     // what happens when we execute (do)
            public abstract void Undo();   // what happens when we unexecute (undo)
        }


        // Add Shape Command - it is a ConcreteCommand Class (extends Command)
        // This adds a Shape to the Canvas as the "Do" action
        public class AddShapeCommand : Command
        {
            Shape shape;
            Canvas canvas;

            public AddShapeCommand(Shape s, Canvas c)
            {
                shape = s;
                canvas = c;
            }

            // Adds a shape to the canvas as "Do" action
            public override void Do()
            {
                canvas.Add(shape);
            }
            // Removes a shape from the canvas as "Undo" action
            public override void Undo()
            {
                shape = canvas.Remove();
            }

        }
        // Entry into application
        static void Main()
        {
            // Create a Canvas which will hold the list of shapes drawn on canvas
            Canvas canvas = new Canvas();
            // Create user and allow user actions shapes to a canvas
            User user = new User();
            Console.Clear();
            bool cont = true;
            string? input = "";
            //string svg = "";
            //strings for storing svg format
            string beginning = "<svg width=\"1000\" height=\"1000\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\">";
            string end = "</svg>";
            WriteLine("List of commands: ");
            WriteLine("A<shape>     Add shape to canvas");
            WriteLine("D            Display Canvas");
            WriteLine("S            Save Canvas");
            WriteLine("U            Undo last operation");
            WriteLine("R            Redo last operation");
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
                        addShape(shape, canvas, user);
                        break;
                    //D - displays canvas
                    case "D":
                        WriteLine(canvas);
                        break;
                    //S - exports canvas to file called canvas.svg
                    case "S":
                        WriteLine("File canvas.svg has been succesfully saved!");
                        File.WriteAllText(@"./canvas.svg", beginning + Environment.NewLine + canvas.ToString() +Environment.NewLine + end);
                        break;
                    //U - undo shape
                    case "U":
                        user.Undo();
                        break;
                    //R - redo shape into canvas
                    case "R":
                        user.Redo();
                        break; 
                    //Q - quit the loop
                    case "Q":
                        WriteLine("Goodbye!");
                        cont = false;
                        break;
                    //H - displays help
                    case "H":                       
                        WriteLine("Commands");
                        WriteLine("A <shape>        Add Shape");
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
    }
}