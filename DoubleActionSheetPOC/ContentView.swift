//
//  ContentView.swift
//  DoubleActionSheetPOC
//
//  Created by Richard Everhart on 12/16/23.
//

import SwiftUI

struct ContentView: View {
    @State var showNumberMenu = false
    @State var showAnimalMenu = false
    @State var showCarMenu = false
    @State var showEmptyDataMenu = false

    var body: some View {
        VStack {
            Button(action: {
                self.showNumberMenu = true
            }, label: {
                Image(systemName: "number")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Number Button")
            })
            .menuSheet($showNumberMenu,
                       initialContent: { InitialMenuView() },
                       secondary: { SecondaryMenuView() })
            Spacer()
            Button(action: {
                self.showAnimalMenu = true
            }, label: {
                Image(systemName: "cat")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Animal Button")
            })
            .menuSheet($showAnimalMenu,
                       initialContent: { AnimalChoiceMenuView() },
                       secondary: { AnimalResultMenuView() })
            Spacer()
            Button(action: {
                self.showCarMenu = true
            }, label: {
                Image(systemName: "car.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Car Button")
            })
            .menuSheet($showCarMenu) {
                CarMenuView()
            }
            Spacer()
            Button(action: {
                self.showEmptyDataMenu = true
            }, label: {
                Image(systemName: "testtube.2")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Empty data Button")
            })
            .menuSheet($showEmptyDataMenu,
                       initialContent: { EmptyDataMenu1() },
                       secondary: { EmptyDataMenu2() })
        }
        .padding(.vertical, 100)
    }
}

extension View {
    func menuSheet<IntialContent: MenuView, SecondaryContent: MenuView>(_ show: Binding<Bool>,
                                                                        initialContent: @escaping () -> IntialContent,
                                                                        secondary:  @escaping() -> SecondaryContent = { EmptyMenu() }) -> some View {
        self.modifier(MenuSheet(showMenu: show, initialMenu: initialContent, secondary: secondary))
    }
}

// MARK: -

// MenuEvents are used to communicate values from the
// initial menu to the secondary menu.
enum MenuEvent {
    case number(Int)
    case cat
    case dog
    case bird
    case empty // triggers 2ndary menu without passing any data
    case none
}

class MenuCoordinator: ObservableObject {
    @Published var secondaryTrigger = false
    @Published var resetToInitial = false
    var event: MenuEvent = .none

    // Used by the initial menu to pass values to the secondary menu.
    func pass(event: MenuEvent = .empty) {
        self.event = event
        secondaryTrigger = true
    }
    
    // Used by the secondary menu to reset the next invocation of the
    // MenuSheet back to the intial menu.  Should be called by every
    // button in the secondary menu.
    func complete() {
        resetToInitial = true
    }
}

// MARK: -

protocol MenuView: View {
    var title: String { get }
}

extension MenuView {
    var title: String { "" }
    
    var body: some View {
        EmptyView()
    }
}

struct EmptyMenu: MenuView {}

// MARK: -

struct MenuSheet<IntialContent: MenuView, SecondaryContent: MenuView>: ViewModifier {
    @State private var coordinator = MenuCoordinator()
    @State private var showSecondary = false
    
    @Binding var showMenu: Bool
    var initialMenu: IntialContent
    var secondary: SecondaryContent
    
    init(showMenu: Binding<Bool>,
         @ViewBuilder initialMenu: @escaping () -> IntialContent,
         @ViewBuilder secondary: @escaping () -> SecondaryContent = { EmptyMenu() }) {
        self._showMenu = showMenu
        self.initialMenu = initialMenu()
        self.secondary = secondary()
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibility(hidden: showMenu)
            .confirmationDialog(menuTitle,
                                isPresented: $showMenu,
                                titleVisibility: menuTitle.isEmpty ? .hidden : .visible) {
                menuContent
            }
            .environmentObject(coordinator)
            .onReceive(coordinator.$secondaryTrigger.dropFirst()) { showSecondary in
                if showSecondary {
                    print("showSecondary is true")
                    self.showSecondary = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showMenu = true
                    }
                }
            }
            .onReceive(coordinator.$resetToInitial) { reset in
                if reset {
                    print("resetToInitial is true")
                    self.showSecondary = false
                    self.showMenu = false
                }
            }
    }
    
    var menuTitle: String {
        if showSecondary {
            secondary.title
        } else {
            initialMenu.title
        }
    }
    
    var menuContent: some View {
        if showSecondary {
            AnyView(secondary)
        } else {
            AnyView(initialMenu)
        }
    }

}

// MARK: - Number menus

struct InitialMenuView: MenuView {
    @EnvironmentObject private var coordinator: MenuCoordinator
    var title: String {
        "Pick a Number"
    }
    
    var body: some View {
        Button("1") {
            coordinator.pass(event: .number(2))
        }
        Button("2") {
            coordinator.pass(event: .number(4))
        }
        Button("3") {
            coordinator.pass(event: .number(6))
        }
    }
}

struct SecondaryMenuView: MenuView {
    @EnvironmentObject private var coordinator: MenuCoordinator
    
    var body: some View {
        if case let .number(number) = coordinator.event {
            ForEach(1..<number + 1, id: \.self) { count in
                Button("\(count)") {
                    print("Secondary recieved: \(count)")
                    coordinator.complete()
                }
            }
            Button("Cancel", role: .cancel) {
                coordinator.complete()
            }
        } else {
            EmptyView()
        }
    }
}

// MARK: - Animal menus

struct AnimalChoiceMenuView: MenuView {
    @EnvironmentObject private var coordinator: MenuCoordinator
    
    var body: some View {
        Button("Cat") {
            coordinator.pass(event: .cat)
        }
        Button("Dog") {
            coordinator.pass(event: .dog)
        }
        Button("Bird") {
            coordinator.pass(event: .bird)
        }
    }
}

struct AnimalResultMenuView: MenuView {
    @EnvironmentObject private var coordinator: MenuCoordinator
    var title: String {
        "You pick an animal"
    }

    var body: some View {
        switch coordinator.event {
            case .cat:
                Button("Long hair") {
                    coordinator.complete()
                }
                Button("Short hair") {
                    coordinator.complete()
                }
                Button("Coon") {
                    coordinator.complete()
                }
            case .dog:
                Button("Chihuahua") {
                    coordinator.complete()
                }
                Button("Bulldog") {
                    coordinator.complete()
                }
                Button("Doberman") {
                    coordinator.complete()
                }

            case .bird:
                Button("Raven") {
                    coordinator.complete()
                }
                Button("Sparrow") {
                    coordinator.complete()
                }
                Button("Hawk") {
                    coordinator.complete()
                }
            default:
                EmptyView()
        }
        Button("Cancel", role: .cancel) {
            coordinator.complete()
        }
    }
}

// MARK: - Car menu

struct CarMenuView: MenuView {
    @EnvironmentObject private var coordinator: MenuCoordinator
    
    var body: some View {
        Button("Sedan") {
        }
        Button("Truck") {
        }
        Button("Hatchback") {
        }
    }
}

// MARK: - Empty Data menu\

struct EmptyDataMenu1: MenuView {
    @EnvironmentObject private var coordinator: MenuCoordinator
    
    var body: some View {
        Button("Open 2ndary") {
            coordinator.pass()
        }
    }
}

struct EmptyDataMenu2: MenuView {
    @EnvironmentObject private var coordinator: MenuCoordinator
    
    var body: some View {
        Button("Hi, I'm 2ndary") {
            coordinator.complete()
        }
        Button("Cancel", role: .cancel) {
            coordinator.complete()
        }
    }
}


#Preview {
    ContentView()
}
