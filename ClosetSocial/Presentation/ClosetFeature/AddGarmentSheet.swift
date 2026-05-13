import SwiftUI

struct AddGarmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddGarmentViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Nueva prenda") {
                    TextField("Nombre", text: $viewModel.name)
                    TextField("Marca", text: $viewModel.brand)
                    Picker("Tipo", selection: $viewModel.type) {
                        ForEach(GarmentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Color", text: $viewModel.color)
                    TextField("Imagen (URL)", text: $viewModel.imageURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Añadir prenda")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Guardar")
                        }
                    }
                    .disabled(viewModel.isSaveDisabled)
                }
            }
        }
    }
}
