import SwiftUI

struct CustomTriggersView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var newPhrase = ""
    @State private var newDescription = ""
    @State private var showingAddTrigger = false
    
    var body: some View {
        List {
            Section(header: Text("Custom Triggers")) {
                ForEach(dataManager.customTriggers) { trigger in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(trigger.phrase)
                                .font(.headline)
                            Text(trigger.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { trigger.isActive },
                            set: { newValue in
                                dataManager.updateTrigger(trigger, isActive: newValue)
                            }
                        ))
                    }
                }
                .onDelete { indexSet in
                    dataManager.deleteTriggers(at: indexSet)
                }
            }
        }
        .navigationTitle("Custom Triggers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTrigger = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTrigger) {
            NavigationView {
                Form {
                    Section(header: Text("New Trigger")) {
                        TextField("Phrase to look for", text: $newPhrase)
                        TextField("Description", text: $newDescription)
                    }
                }
                .navigationTitle("Add Trigger")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddTrigger = false
                    },
                    trailing: Button("Save") {
                        if !newPhrase.isEmpty {
                            dataManager.addTrigger(phrase: newPhrase, description: newDescription)
                            newPhrase = ""
                            newDescription = ""
                            showingAddTrigger = false
                        }
                    }
                )
            }
        }
    }
} 